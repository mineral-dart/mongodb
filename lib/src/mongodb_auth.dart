class MongoDBAuth {
  final String _username;
  final String _password;

  MongoDBAuth(this._username, this._password);

  @override
  String toString () => '$_username:$_password';
}
