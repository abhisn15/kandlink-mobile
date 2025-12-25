// App State Machine for Authentication + Verification + Role + Assignment

enum AuthState {
  unauthenticated, // Belum login
  authenticating, // Sedang login
  authenticated, // Sudah login
}

enum VerificationState {
  unverified, // Belum verifikasi email & whatsapp
  emailPending, // Email belum verified
  whatsappPending, // Email verified, whatsapp belum
  verified, // Email & whatsapp verified
}

enum UserRole {
  candidate, // Kandidat - perlu assign PIC
  pic, // PIC - langsung ke chat
}

enum AssignmentState {
  unassigned, // Belum assign PIC (kandidat)
  assigning, // Sedang assign PIC
  assigned, // Sudah assign PIC
}

class AppUserState {
  final AuthState authState;
  final VerificationState verificationState;
  final UserRole? role;
  final AssignmentState assignmentState;

  final String? userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? areaId;
  final String? picId;
  final String? picName;

  const AppUserState({
    this.authState = AuthState.unauthenticated,
    this.verificationState = VerificationState.unverified,
    this.role,
    this.assignmentState = AssignmentState.unassigned,
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.areaId,
    this.picId,
    this.picName,
  });

  // Factory constructors for common states
  factory AppUserState.initial() => const AppUserState();

  factory AppUserState.authenticated({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? areaId,
    String? picId,
    String? picName,
  }) {
    VerificationState verificationState;

    // TODO: Determine verification state from user data
    // For now, assume verified if authenticated
    verificationState = VerificationState.verified;

    AssignmentState assignmentState;
    if (role == UserRole.pic) {
      assignmentState = AssignmentState.assigned; // PIC selalu assigned
    } else {
      assignmentState =
          picId != null ? AssignmentState.assigned : AssignmentState.unassigned;
    }

    return AppUserState(
      authState: AuthState.authenticated,
      verificationState: verificationState,
      role: role,
      assignmentState: assignmentState,
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      areaId: areaId,
      picId: picId,
      picName: picName,
    );
  }

  // Helper methods
  bool get isAuthenticated => authState == AuthState.authenticated;
  bool get isEmailVerified =>
      verificationState != VerificationState.emailPending &&
      verificationState != VerificationState.unverified;
  bool get isWhatsappVerified =>
      verificationState == VerificationState.verified;
  bool get isFullyVerified => isEmailVerified && isWhatsappVerified;
  bool get needsEmailVerification =>
      verificationState == VerificationState.emailPending ||
      verificationState == VerificationState.unverified;
  bool get needsWhatsappVerification =>
      verificationState == VerificationState.whatsappPending;
  bool get needsAreaSelection =>
      role == UserRole.candidate &&
      assignmentState == AssignmentState.unassigned;
  bool get canAccessChat =>
      isAuthenticated &&
      isFullyVerified &&
      (role == UserRole.pic || assignmentState == AssignmentState.assigned);

  // Copy with method for state updates
  AppUserState copyWith({
    AuthState? authState,
    VerificationState? verificationState,
    UserRole? role,
    AssignmentState? assignmentState,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? areaId,
    String? picId,
    String? picName,
  }) {
    return AppUserState(
      authState: authState ?? this.authState,
      verificationState: verificationState ?? this.verificationState,
      role: role ?? this.role,
      assignmentState: assignmentState ?? this.assignmentState,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      areaId: areaId ?? this.areaId,
      picId: picId ?? this.picId,
      picName: picName ?? this.picName,
    );
  }

  @override
  String toString() {
    return 'AppUserState(auth: $authState, verification: $verificationState, '
        'role: $role, assignment: $assignmentState, userId: $userId, '
        'areaId: $areaId, picId: $picId)';
  }
}

// Navigation guard logic
class NavigationGuard {
  static String? getRedirectPath(AppUserState state) {
    // 1. Belum login → Login
    if (!state.isAuthenticated) {
      return '/login';
    }

    // 2. Sudah login tapi email belum verified → Email verification
    if (state.needsEmailVerification) {
      return '/email-verification';
    }

    // 3. Email verified tapi whatsapp belum verified → WhatsApp verification
    if (state.needsWhatsappVerification) {
      return '/whatsapp-verification';
    }

    // 4. Fully verified, cek role dan assignment
    if (state.isFullyVerified) {
      if (state.role == UserRole.candidate) {
        // Kandidat perlu assign PIC
        if (state.needsAreaSelection) {
          return '/area-selection';
        } else {
          // Sudah assign PIC → ke home (dashboard)
          return '/home';
        }
      } else if (state.role == UserRole.pic) {
        // PIC langsung ke conversations
        return '/conversations';
      }
    }

    // Default: kembali ke login jika state tidak valid
    return '/login';
  }

  static bool canAccessPath(String path, AppUserState state) {
    final requiredPath = getRedirectPath(state);

    // Jika perlu redirect ke path lain, berarti tidak boleh akses path ini
    if (requiredPath != null && requiredPath != path) {
      return false;
    }

    return true;
  }
}
