import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart' as local_user;
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool _isLoading = false.obs;
  final RxBool _isOTPVerified = false.obs;

  final Rx<local_user.User?> _user = Rx<local_user.User?>(null);
  local_user.User? get user => _user.value;

  final RxBool _isSignedIn = false.obs;
  bool get isSignedIn => _isSignedIn.value;

  bool get isLoading => _isLoading.value;

  String? _verificationId;
  String? _phoneNumber;
  String? _userName;

  String? get phoneNumber => _phoneNumber;

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen(_handleAuthStateChange);
    _checkRememberedUser();
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool('remember_me') ?? false;

    if (isRemembered && _auth.currentUser != null) {
      _isSignedIn.value = true;
    }
  }

  void _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _user.value = local_user.User.fromMap(userDoc.data()!);
      } else {
        final newUser = local_user.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          phoneNumber: firebaseUser.phoneNumber,
          name: firebaseUser.displayName ?? 'User',
          photoUrl: firebaseUser.photoURL,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
        _user.value = newUser;
      }

      _isSignedIn.value = true;
    } else {
      _user.value = null;
      _isSignedIn.value = false;
    }
  }
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    bool rememberMe,
  ) async {
    _isLoading.value = true;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          final newUser = local_user.User(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email,
            name: userCredential.user!.displayName ?? 'User',
            photoUrl: userCredential.user!.photoURL,
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toMap());
          _user.value = newUser;
        } else {
          _user.value = local_user.User.fromMap(userDoc.data()!);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);

        _isSignedIn.value = true;
        _isLoading.value = false;

        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = 'An error occurred during sign in: ${e.message}';
      }
      Get.snackbar(
        'Sign In Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to sign in: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    bool rememberMe,
  ) async {
    _isLoading.value = true;
    _userName = name;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final newUser = local_user.User(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          name: name,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
        _user.value = newUser;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);

        _isSignedIn.value = true;
        _isLoading.value = false;

        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String message;
      if (e.code == 'email-already-in-use') {
        message =
            'An account already exists with this email. Please sign in instead.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Please use a stronger password.';
      } else {
        message = 'An error occurred during sign up: ${e.message}';
      }
      Get.snackbar(
        'Sign Up Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to sign up: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _isLoading.value = false;
        Get.snackbar(
          'Error',
          'No account found with this email address.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _auth.sendPasswordResetEmail(email: email);
      _isLoading.value = false;
      Get.snackbar(
        'Password Reset Email Sent',
        'Please check your email (including spam/junk folder) for instructions to reset your password.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found with this email address.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = 'An error occurred: ${e.message}';
      }
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to send password reset email. Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    _isLoading.value = true;
    _phoneNumber = phoneNumber;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading.value = false;
          String message;
          if (e.code == 'invalid-phone-number') {
            message = 'The provided phone number is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            message = 'Quota exceeded. Please try again later.';
          } else {
            message = 'An error occurred during verification: ${e.message}';
          }
          Get.snackbar(
            'Verification Failed',
            message,
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _isLoading.value = false;
          _verificationId = verificationId;
          _isOTPVerified.value = false;
          Get.toNamed(AppRoutes.verifyOTP);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String message;
      if (e.code == 'invalid-phone-number') {
        message = 'The provided phone number is invalid.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please try again later.';
      } else if (e.code == 'quota-exceeded') {
        message = 'Quota exceeded. Please try again later.';
      } else {
        message = 'An error occurred during verification: ${e.message}';
      }
      Get.snackbar(
        'Verification Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to send OTP: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          String userName = _userName ?? 'User';

          if (_userName == null && _phoneNumber != null) {
            final phoneUserQuery = await _firestore
                .collection('users')
                .where('phoneNumber', isEqualTo: _phoneNumber)
                .limit(1)
                .get();

            if (phoneUserQuery.docs.isNotEmpty) {
              userName = phoneUserQuery.docs.first.data()['name'] ?? userName;
            }
          }

          final newUser = local_user.User(
            uid: userCredential.user!.uid,
            phoneNumber: userCredential.user!.phoneNumber ?? _phoneNumber ?? '',
            name: userName,
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toMap());
          _user.value = newUser;
        } else {
          final existingUser = local_user.User.fromMap(userDoc.data()!);
          String updatedName = existingUser.name;

          if (_userName != null && existingUser.name == 'User') {
            updatedName = _userName!;
          }

          String updatedPhone = existingUser.phoneNumber ?? '';
          if (userCredential.user!.phoneNumber != null &&
              userCredential.user!.phoneNumber != updatedPhone) {
            updatedPhone = userCredential.user!.phoneNumber!;
          } else if (_phoneNumber != null && _phoneNumber != updatedPhone) {
            updatedPhone = _phoneNumber!;
          }

          final updatedUser = local_user.User(
            uid: existingUser.uid,
            email: existingUser.email,
            phoneNumber: updatedPhone,
            name: updatedName,
            photoUrl: existingUser.photoUrl,
          );

          if (updatedUser.name != existingUser.name ||
              updatedUser.phoneNumber != existingUser.phoneNumber) {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(updatedUser.toMap());
          }

          _user.value = updatedUser;
        }

        _isSignedIn.value = true;
        _isOTPVerified.value = true;
        _isLoading.value = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          'remember_me',
          true,
        );

        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to sign in: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> verifyOTP(String otp) async {
    _isLoading.value = true;

    try {
      if (_verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );

        await _signInWithPhoneCredential(credential);
      } else {
        _isLoading.value = false;
        Get.snackbar(
          'Error',
          'Verification ID not found. Please request OTP again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String message;
      if (e.code == 'invalid-verification-code') {
        message = 'The provided OTP is invalid.';
      } else if (e.code == 'session-expired') {
        message =
            'The verification code has expired. Please request a new OTP.';
      } else {
        message = 'An error occurred during verification: ${e.message}';
      }
      Get.snackbar(
        'Verification Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to verify OTP: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signInWithPhoneNumber(
    String phoneNumber,
    bool rememberMe,
  ) async {
    await sendOTP(phoneNumber);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user.value = null;
      _isSignedIn.value = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Sign Out Failed',
        'An error occurred during sign out.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    try {
      if (_user.value == null) {
        Get.snackbar(
          'Error',
          'No user logged in',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final updatedUser = _user.value!.copyWith(name: name, photoUrl: photoUrl);

      await _firestore
          .collection('users')
          .doc(_user.value!.uid)
          .set(updatedUser.toMap());

      _user.value = updatedUser;

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> resendOTP() async {
    if (_phoneNumber != null) {
      await sendOTP(_phoneNumber!);
    } else {
      Get.snackbar(
        'Error',
        'Phone number not found. Please enter phone number again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
