import 'dart:io';
import 'package:path_provider/path_provider.dart';

class InputStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/savedInput.txt');
  }

  Future<String> readSavedInput() async {
    try {
      final file = await _localFile;
      String savedInputs = await file.readAsString();
      return savedInputs;
    } catch (e) {
      print('read saved input error');
      print(e);
      return 'read saved input error';
    }    
  }

  Future<File> saveInput(String input) async {
    final file = await _localFile;
    return file.writeAsString(input);
  }
}

class HistoryStorge {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/searchedHistory.txt');
  }

  Future<String> readHistory() async {
    try {
      final file = await _localFile;
      String searchedHistory = await file.readAsString();
      return searchedHistory;
    } catch (e) {
      print('read history error');
      print(e);
      return 'read history error:';
    }
  }

  Future<File> writeHistory(String searchedHistory) async {
    final file = await _localFile;
    return file.writeAsString(searchedHistory);
  }
}