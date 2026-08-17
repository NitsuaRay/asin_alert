import 'package:asin_alert/services/admin_service.dart';
import 'package:flutter/material.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final AdminService _adminService = AdminService();
  String _filter = 'all'; // 'all', 'pending', 'verified'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserFormDialog(context),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Tabs
            Row(
              children: [
                Expanded(child: _buildSegmentButton('all', 'All Users')),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSegmentButton('pending', 'Pending Approvals'),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildSegmentButton('verified', 'Verified')),
              ],
            ),
            const SizedBox(height: 16),

            // User List Stream
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _adminService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allUsers = snapshot.data ?? [];
                  final filteredUsers = allUsers.where((u) {
                    if (_filter == 'pending') return u['is_verified'] == false;
                    if (_filter == 'verified') return u['is_verified'] == true;
                    return true;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No users found in this view',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isVerified = user['is_verified'] == true;
                      final role = (user['role'] ?? 'user').toString();
                      final userId = user['id']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF0F172A).withOpacity(0.08),
                            child: Icon(
                              role == 'police'
                                  ? Icons.local_police_rounded
                                  : role == 'establishment'
                                      ? Icons.store_rounded
                                      : Icons.person_rounded,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['full_name'] ??
                                      user['establishment_name'] ??
                                      'Unnamed User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${role.toUpperCase()} • ${user['email'] ?? 'No Email'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pending Approvals Actions
                              if (!isVerified) ...[
                                IconButton(
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  ),
                                  tooltip: 'Approve User',
                                  onPressed: () =>
                                      _adminService.approveUser(userId),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Deny User',
                                  onPressed: () => _confirmAction(
                                    context,
                                    title: 'Deny User',
                                    content:
                                        'Are you sure you want to deny and remove this user application?',
                                    onConfirm: () =>
                                        _adminService.denyUser(userId),
                                  ),
                                ),
                              ],

                              // Contextual Edit/Delete Menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showUserFormDialog(
                                      context,
                                      existingUser: user,
                                    );
                                  } else if (value == 'delete') {
                                    _confirmAction(
                                      context,
                                      title: 'Delete User',
                                      content:
                                          'Are you sure you want to permanently delete this user profile?',
                                      onConfirm: () =>
                                          _adminService.deleteUser(userId),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit User'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String value, String label) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DIALOGS & FORM HELPERS
  // ===========================================================================

  void _showUserFormDialog(
    BuildContext context, {
    Map<String, dynamic>? existingUser,
  }) {
    final isEditing = existingUser != null;
    final nameController = TextEditingController(
      text: existingUser?['full_name'] ?? existingUser?['establishment_name'] ?? '',
    );
    final emailController = TextEditingController(
      text: existingUser?['email'] ?? '',
    );
    String selectedRole = existingUser?['role'] ?? 'user';
    bool isVerified = existingUser?['is_verified'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // 👈 Fixed from StatefulWidget to StatefulBuilder
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEditing ? 'Edit User Profile' : 'Add New User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name / Establishment Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(
                          value: 'establishment',
                          child: Text('Establishment'),
                        ),
                        DropdownMenuItem(
                          value: 'police',
                          child: Text('Police'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Is Verified'),
                      value: isVerified,
                      onChanged: (val) {
                        setModalState(() => isVerified = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final payload = {
                      'full_name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'role': selectedRole,
                      'is_verified': isVerified,
                    };

                    if (isEditing) {
                      await _adminService.updateUser(
                        existingUser['id'].toString(),
                        payload,
                      );
                    } else {
                      await _adminService.addUser(payload);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create User',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}