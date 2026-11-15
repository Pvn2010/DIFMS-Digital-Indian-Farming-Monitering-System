
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'government_farmer_detail_screen.dart';
import 'government_password_screen.dart';

class GovernmentDashboardScreen extends StatefulWidget {
  const GovernmentDashboardScreen({super.key});

  @override
  State<GovernmentDashboardScreen> createState() =>
      _GovernmentDashboardScreenState();
}

class _GovernmentDashboardScreenState
    extends State<GovernmentDashboardScreen> {
  final TextEditingController _search = TextEditingController();

  static final Uri _emailEndpoint = Uri.parse(
    'https://script.google.com/macros/s/'
        'AKfycbzxjD9LLuNwU8vujqx2fc_kU0sPYz4n5eB0sVZtnmg6DTjXOmr4NKttUzXTgUMVkmwU/exec',
  );

  String _district = 'All districts';
  bool _sendingBulkReminder = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // Saves an individual in-app reminder record.
  // This function does not send an email.
  Future<void> _sendReminder(
      Map<String, dynamic> farmer,
      ) async {
    final flin = (farmer['flin'] ?? '').toString().trim();

    if (flin.isEmpty) {
      _showMessage('This farmer has no FLIN.');
      return;
    }

    final messageController = TextEditingController(
      text:
      'Please submit this week’s crop photos and observations in DIFMS.',
    );

    try {
      final send = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Weekly photo reminder · $flin'),
          content: TextField(
            controller: messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reminder message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Create reminder'),
            ),
          ],
        ),
      );

      if (send != true || !mounted) return;

      final message = messageController.text.trim();

      if (message.isEmpty) {
        _showMessage('Please enter a reminder message.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('farmerNotifications')
          .add({
        'farmerFlin': flin,
        'farmerName': (farmer['name'] ?? '').toString(),
        'title': 'Weekly crop photo reminder',
        'message': message,
        'type': 'weekly_photo_reminder',
        'status': 'created',
        'createdByUid':
        FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'acknowledgedAt': null,
      });

      _showMessage(
        'Reminder record created. No email has been sent.',
      );
    } catch (e) {
      _showMessage('Could not create reminder: $e');
    } finally {
      messageController.dispose();
    }
  }

  // Calls the deployed Apps Script endpoint.
  // The server must independently verify the officer's token,
  // government claim, active status, and bulk-send authorization.
  Future<void> _remindAllFarmers(
      List<Map<String, dynamic>> farmers,
      ) async {
    if (_sendingBulkReminder) return;

    final eligible = farmers.where((farmer) {
      final email = (farmer['email'] ?? '').toString().trim();

      return email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
              .hasMatch(email);
    }).toList();

    final skipped = farmers.length - eligible.length;

    if (eligible.isEmpty) {
      _showMessage(
        'No farmers with valid saved email addresses. '
            '$skipped farmer(s) skipped.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remind All Farmers?'),
        content: Text(
          'The email service will process all farmers in the '
              'current list who have valid saved email addresses.\n\n'
              'Farmers to process: ${eligible.length}\n'
              'Missing or invalid email addresses: $skipped\n\n'
              'Continue only if you are authorized to send these '
              'official reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Send reminders'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session has expired. Please sign in again.');
      return;
    }

    setState(() => _sendingBulkReminder = true);

    try {
      final idToken = await user.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Could not obtain an authentication token. Sign in again.',
        );
      }

      final response = await http
          .post(
        _emailEndpoint,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
          'message':
          'Please submit this week’s crop photos and field '
              'observations through the DIFMS application.',
        }),
      )
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      // Apps Script may return HTML after a redirect or deployment
      // error. Never treat a non-JSON response as a successful send.

      final responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        throw Exception(
          'The email service returned an empty response. '
              'Check the Apps Script deployment and execution logs.',
        );
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        throw Exception(
          'The email service returned a non-JSON response. '
              'Check Apps Script Executions for the server error.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response from the email service.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['ok'] != true) {
        throw Exception(
          (decoded['error'] ?? 'Email request failed.').toString(),
        );
      }

      final sent = decoded['sent'] ?? 0;
      final serverSkipped = decoded['skipped'] ?? 0;
      final failed = decoded['failed'] ?? 0;

      _showMessage(
        'Email service finished: sent $sent, '
            'skipped $serverSkipped, failed $failed.',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['ok'] != true) {
        throw Exception(
          (decoded['error'] ?? 'Email service rejected the request.')
              .toString(),
        );
      }
      _showMessage(
        'Email service finished: sent $sent, '
            'skipped $serverSkipped, failed $failed.',
      );
    } catch (e) {
      _showMessage(
        'Could not confirm bulk email results: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _sendingBulkReminder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ??
            'Government officer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIFMS Government'),
        actions: [
          IconButton(
            tooltip: 'Change password',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const GovernmentPasswordScreen(),
                ),
              );
            },
            icon: const Icon(Icons.key_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load farmer registry. '
                      'Check Firestore rules.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final all = snapshot.data!.docs.map((doc) {
            return {
              ...doc.data(),
              'flin': doc.data()['flin'] ?? doc.id,
            };
          }).toList();

          final districts = all
              .map((farmer) =>
              (farmer['district'] ?? '').toString())
              .where((district) => district.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          if (_district != 'All districts' &&
              !districts.contains(_district)) {
            _district = 'All districts';
          }

          final query = _search.text.trim().toLowerCase();

          final farmers = all.where((farmer) {
            final district =
            (farmer['district'] ?? '').toString();

            final matchesDistrict =
                _district == 'All districts' ||
                    district == _district;

            final searchableText = [
              farmer['flin'],
              farmer['name'],
              farmer['village'],
              district,
              farmer['surveyNumber'],
            ].map((value) => (value ?? '').toString())
                .join(' ')
                .toLowerCase();

            return matchesDistrict &&
                searchableText.contains(query);
          }).toList()
            ..sort(
                  (a, b) => (a['name'] ?? '')
                  .toString()
                  .compareTo((b['name'] ?? '').toString()),
            );

          final width = MediaQuery.sizeOf(context).width;

          final columns = width >= 1100
              ? 4
              : width >= 760
              ? 3
              : width >= 520
              ? 2
              : 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farmer observation portal',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Signed in: $email'),
                      const SizedBox(height: 8),
                      const Text(
                        'Use FLIN to review registered fields, crops, '
                            'weekly photos, and reporting follow-up.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      (constraints.maxWidth -
                          (columns - 1) * 10) /
                          columns;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatCard(
                        width: cardWidth,
                        label: 'Registered farmers',
                        value: '${all.length}',
                        icon: Icons.people_alt_outlined,
                      ),
                      _StatCard(
                        width: cardWidth,
                        label: 'Districts represented',
                        value: '${districts.length}',
                        icon: Icons.map_outlined,
                      ),
                      _StatCard(
                        width: cardWidth,
                        label: 'Search results',
                        value: '${farmers.length}',
                        icon: Icons.manage_search,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                  farmers.isEmpty || _sendingBulkReminder
                      ? null
                      : () => _remindAllFarmers(farmers),
                  icon: _sendingBulkReminder
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.mark_email_read_outlined,
                  ),
                  label: Text(
                    _sendingBulkReminder
                        ? 'Sending reminders...'
                        : 'Remind All Farmers',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText:
                  'Search FLIN, farmer, village, survey number…',
                  border: const OutlineInputBorder(),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _district,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filter by district',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'All districts',
                  ...districts,
                ].map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _district = value ?? 'All districts';
                  });
                },
              ),

              const SizedBox(height: 12),

              Text(
                'Farmer registry (${farmers.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              if (farmers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No farmers match this search.'),
                ),

              ...farmers.map((farmer) {
                final flin =
                (farmer['flin'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.agriculture),
                          ),
                          title: Text(
                            (farmer['name'] ??
                                'Unnamed farmer')
                                .toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'FLIN: $flin\n'
                                '${farmer['village'] ?? 'Village not recorded'}, '
                                '${farmer['district'] ?? 'District not recorded'}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GovernmentFarmerDetailScreen(
                                      farmer: farmer,
                                    ),
                              ),
                            );
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GovernmentFarmerDetailScreen(
                                            farmer: farmer,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                ),
                                label: const Text('Observe'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    _sendReminder(farmer),
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                label: const Text('Remind'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              const Text(
                'Individual reminders currently create in-app records. '
                    'Bulk email requests require a working, authenticated '
                    'server-side email sender.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFD166),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: const Color(0xFF246B3B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
