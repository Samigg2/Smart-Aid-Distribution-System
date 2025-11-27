import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading users',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                List<UserModel> users = snapshot.data!;

                // Filter users based on search query
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) {
                    return user.fullName.toLowerCase().contains(_searchQuery) ||
                        user.email.toLowerCase().contains(_searchQuery) ||
                        user.phone.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: user.isAdmin ? Colors.purple[100] : Colors.blue[100],
                  radius: 25,
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.badge,
                    color: user.isAdmin ? Colors.purple[700] : Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.isAdmin
                                  ? Colors.purple[50]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.isAdmin
                                    ? Colors.purple[700]
                                    : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        user.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Additional Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status
                Row(
                  children: [
                    Icon(
                      user.isActive ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: user.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Created Date
                Text(
                  'Created: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleUserStatus(user),
                    icon: Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                      size: 16,
                    ),
                    label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          user.isActive ? Colors.orange[700] : Colors.green[700],
                      side: BorderSide(
                        color: user.isActive ? Colors.orange[300]! : Colors.green[300]!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _firestoreService.updateUser(user.uid, {
                  'fullName': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'role': selectedRole,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate User?' : 'Activate User?'),
        content: Text(
          user.isActive
              ? 'This user will not be able to login until reactivated.'
              : 'This user will be able to login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isActive ? Colors.orange[700] : Colors.green[700],
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.toggleUserStatus(user.uid, user.isActive);
    }
  }
}

