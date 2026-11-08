import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _avatarUrlController;

  String? _selectedAvatarUrl;
  bool _hasCustomUrl = false;

  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameFeedback;

  static const List<Map<String, String>> _avatarPresets = [
    {
      'label': 'The Classicist',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    },
    {
      'label': 'The Scholar',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    },
    {
      'label': 'The Novelist',
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    },
    {
      'label': 'The Poet',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    },
    {
      'label': 'The Essayist',
      'url': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&auto=format&fit=crop&q=80',
    },
    {
      'label': 'The Philosopher',
      'url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _selectedAvatarUrl = user?.avatarUrl;
    _isUsernameAvailable = true;
    _usernameFeedback = 'Current handle';
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _displayNameController.dispose();
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value, UserEntity? currentUser) {
    _usernameDebounce?.cancel();
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameFeedback = null;
      });
      return;
    }

    if (currentUser != null && clean == currentUser.username.toLowerCase()) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = true;
        _usernameFeedback = 'Current handle';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(clean)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameFeedback = 'Must be 3–30 letters, numbers, or _';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameFeedback = 'Checking availability...';
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final authRepo = context.read<AuthRepository>();
        final res = await authRepo.checkUsernameAvailability(clean);
        if (!mounted || _usernameController.text.trim().toLowerCase() != clean) return;

        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = res['available'] == true;
          _usernameFeedback = res['message'] as String? ??
              (res['available'] == true ? '@$clean is available' : '@$clean is taken');
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
        });
      }
    });
  }

  void _onSave(UserEntity? currentUser) {
    if (!_formKey.currentState!.validate()) return;
    if (_isUsernameAvailable == false) return;

    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final avatarUrl = _selectedAvatarUrl?.trim();

    context.read<AuthBloc>().add(
          UpdateProfileEvent(
            displayName: displayName != currentUser?.displayName ? displayName : null,
            username: username != currentUser?.username ? username : null,
            avatarUrl: avatarUrl != currentUser?.avatarUrl ? avatarUrl : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          if (context.canPop()) {
            context.pop();
          }
        }
      },
      builder: (context, state) {
        final user = state.user;
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            actions: [
              TextButton(
                onPressed: (isLoading || _isCheckingUsername || _isUsernameAvailable == false)
                    ? null
                    : () => _onSave(user),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Avatar Preview
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: (_selectedAvatarUrl != null &&
                                  _selectedAvatarUrl!.isNotEmpty)
                              ? NetworkImage(_selectedAvatarUrl!)
                              : null,
                          child: (_selectedAvatarUrl == null ||
                                  _selectedAvatarUrl!.isEmpty)
                              ? Text(
                                  _displayNameController.text.isNotEmpty
                                      ? _displayNameController.text[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Choose an Avatar',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Presets Row
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatarPresets.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Monogram / Initials option
                          final isSelected = _selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatarUrl = null;
                                _avatarUrlController.clear();
                              });
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  LucideIcons.user,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        }

                        final preset = _avatarPresets[index - 1];
                        final url = preset['url']!;
                        final isSelected = _selectedAvatarUrl == url;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarUrl = url;
                              _avatarUrlController.text = url;
                            });
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(url),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Custom Image URL option
                  GestureDetector(
                    onTap: () => setState(() => _hasCustomUrl = !_hasCustomUrl),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasCustomUrl ? LucideIcons.chevronUp : LucideIcons.link,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hasCustomUrl ? 'Hide Custom URL' : 'Use Custom Image URL',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_hasCustomUrl) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _avatarUrlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Image Web URL',
                        hintText: 'https://example.com/avatar.jpg',
                        prefixIcon: const Icon(LucideIcons.image, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.check),
                          onPressed: () {
                            setState(() {
                              _selectedAvatarUrl = _avatarUrlController.text.trim();
                            });
                          },
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedAvatarUrl = val.trim();
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Display Name Field
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'e.g. Alice Reader',
                      prefixIcon: Icon(LucideIcons.user, size: 20),
                      helperText: 'Your public name visible to other readers and clubs',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Display name cannot be empty';
                      }
                      if (val.trim().length > 50) {
                        return 'Display name cannot exceed 50 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Username / Handle Field with Real-Time Debounced Availability Check
                  TextFormField(
                    controller: _usernameController,
                    autocorrect: false,
                    onChanged: (val) => _onUsernameChanged(val, user),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'bookworm',
                      prefixIcon: const Icon(LucideIcons.atSign, size: 20),
                      suffixIcon: _isCheckingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _isUsernameAvailable == true
                              ? const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20)
                              : _isUsernameAvailable == false
                                  ? Icon(LucideIcons.alertCircle, color: theme.colorScheme.error, size: 20)
                                  : null,
                      helperText: _usernameFeedback ??
                          'Unique handle (3–30 chars, letters, numbers, underscores)',
                      helperStyle: _usernameFeedback != null
                          ? TextStyle(
                              color: _isUsernameAvailable == true
                                  ? Colors.green
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      final clean = val.trim().toLowerCase();
                      if (clean.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (clean.length > 30) {
                        return 'Username cannot exceed 30 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
                        return 'Only letters, numbers, and underscores are allowed';
                      }
                      if (_isUsernameAvailable == false) {
                        return _usernameFeedback ?? 'Username is already taken';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field (Read-only)
                  TextFormField(
                    initialValue: user?.email ?? 'Not provided',
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Connected Email',
                      prefixIcon: const Icon(LucideIcons.mail, size: 20),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.lock, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Linked',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: (isLoading || _isCheckingUsername || _isUsernameAvailable == false)
                          ? null
                          : () => _onSave(user),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.save),
                      label: Text(
                        isLoading ? 'Saving Changes...' : 'Save Profile',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
