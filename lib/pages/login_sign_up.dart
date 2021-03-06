import 'package:ezsgame/firebase/authentication.dart';
import 'package:ezsgame/pages/signup.dart';
import 'package:ezsgame/pages/forgotPassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:ezsgame/pages/SizeConfig.dart';

// Used for testing
class EmailFieldValidator{
  static String validate(String value){
    return value.isEmpty ? 'Email kan inte vara tom' : null;
  }
}

// Used for testing
class LoginFieldValidator{
  static String validate(String value){
    return value.isEmpty ? 'Lösenordet kan inte vara tomt' : null;
  }
}

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallback});

  final BaseAuth auth;
  final VoidCallback loginCallback;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = new GlobalKey<FormState>();

  SizeConfig sizeConfig;

  String _email;
  String _password;
  String _errorMessage;

  bool _isLoginForm;
  bool _isLoading;
  bool showPassword = false;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        userId = await widget.auth.signIn(_email, _password);
        if (userId == null) {
          //meaning the email hasn't been verified
          setState(() {
            _isLoading = false;
            _errorMessage = "E-postadressen har inte verifierats än.";
          });
          return;
        }
        print('Signed in: $userId');

        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _isLoginForm) {
          widget.loginCallback();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
      }
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    sizeConfig = SizeConfig();
    sizeConfig.init(context);
    return new Scaffold(
        body: Stack(
      children: <Widget>[
        _showForm(),
        _showCircularProgress(),
      ],
    ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showForm() {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Padding(
            padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 10, right: SizeConfig.blockSizeHorizontal * 10, top: SizeConfig.blockSizeVertical), // Please understand that all numerical factors here, and in every other place SizeConfig is used, are completely arbitrary and based solely on what looked good on my phone. -Julius :)
            child: new Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  showLogo(), // done
                  showEmailInput(),
                  showPasswordInput(),
                  showErrorMessage(),
                  showPrimaryButton(),
                  showForgotPassword(),
                  showSignup(),
                  facebookSignin(),
                  googleSignin(),
                ],
              ),
            )));
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      _isLoading = false;
      return new Container(
        padding: EdgeInsets.only(top: 15),
        alignment: Alignment.bottomCenter,
        child: Text(
          _errorMessage,
          style: TextStyle(
              fontSize: 13.0,
              color: Colors.red,
              height: 1.0,
              fontWeight: FontWeight.w300),
        ),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return Container(
      alignment: Alignment(0, -0.7),
      padding: EdgeInsets.only(top: SizeConfig.blockSizeVertical * 4, bottom: SizeConfig.blockSizeVertical),
      child: Image.asset(
        "assets/logo.png",
        width: 95,
        height: 95,
//        fit: BoxFit.cover,
      ),
    );
  }

  Widget showEmailInput() {
    return Container(
      padding: EdgeInsets.only(top: SizeConfig.blockSizeVertical * 4, left: 15, right: 15),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Email',
          border: OutlineInputBorder(),
        ),
        key: Key('email'),
        validator: EmailFieldValidator.validate,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Container(
      padding: EdgeInsets.only(top: SizeConfig.blockSizeVertical * 3, bottom: SizeConfig.blockSizeVertical * 2, left: 15, right: 15),
      child: new TextFormField(
        maxLines: 1,
        obscureText: !showPassword,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Lösenord',
          border: OutlineInputBorder(),
          suffixIcon: showPasswordVisibility(),
        ),
        key: Key('password'),
        validator: LoginFieldValidator.validate,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  IconButton showPasswordVisibility() {
    return IconButton(
      icon: !showPassword ? Icon(Icons.visibility): Icon(Icons.visibility_off),
      onPressed: () {
          showPassword = !showPassword;
      },
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
        child: new Text(
            _isLoginForm ? 'Create an account' : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: toggleFormMode);
  }

  Widget showPrimaryButton() {
    return new Container(
        padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal * 25, right: SizeConfig.blockSizeHorizontal * 25),
        child: RaisedButton(
          textColor: Colors.black,
          color: Colors.orangeAccent,
          child: Text('Logga in'),
          key: Key('LogInButton'),
          onPressed: validateAndSubmit,
        ));
  }

  Widget showForgotPassword() {
    return FlatButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPassword(
              auth: widget.auth, loginCallback: widget.loginCallback)));
      },
      textColor: Colors.orangeAccent,
      child: Text('Glömt ditt lösenord?'),
    );
  }

  Widget showSignup() {
    return Container(
        height: SizeConfig.blockSizeVertical * 6,
        child: Row(
      children: <Widget>[
        Text('Har du inget konto?'),
        FlatButton(
          textColor: Colors.orangeAccent,
          child: Text(
            'Registrera dig',
            style: TextStyle(
              fontSize: 15,
              decoration: TextDecoration.underline,
            ),
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SignupPage(
                        auth: widget.auth,
                        loginCallback: widget.loginCallback)));
          },
        )
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    ));
  }

  Widget googleSignin() {
    return Container(
      height: 50,
      padding: EdgeInsets.only(top: 0),
      child: Column(
        children: <Widget>[
          SizedBox(height: 2),
          GoogleSignInButton(
            onPressed: validateGoogleSignIn,
            darkMode: true,
          ),
        ],
      ),
    );
  }

  void validateGoogleSignIn() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    String userId = "";
    try {
      userId = await widget.auth.signInWithGoogle();

      print('Signed in: $userId');

      setState(() {
        _isLoading = false;
      });

      if (userId.length > 0 && userId != null) {
        widget.loginCallback();
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Widget facebookSignin() {
    return Container(
      height: SizeConfig.blockSizeVertical * 10,
      padding: EdgeInsets.only(top: 0),
      child: Column(
        children: <Widget>[
          SizedBox(height: 10),
          FacebookSignInButton(
            onPressed: validateFacebookSignIn,
          )
        ],
      ),
    );
  }

  void validateFacebookSignIn() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    String userId = "";
    try {
      userId = await widget.auth.signInWithFacebook();

      print('Signed in: $userId');

      setState(() {
        _isLoading = false;
      });

      if (userId.length > 0 && userId != null) {
        widget.loginCallback();
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}
