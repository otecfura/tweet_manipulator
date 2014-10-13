import 'dart:convert' show HtmlEscape;
import 'dart:html';
import 'package:csv/csv.dart';


class TwitterManipulator {
  FormElement _readForm;
  InputElement _fileInput;
  Element _dropZone;
  OutputElement _output;
  HtmlEscape sanitizer = new HtmlEscape();
  List<Tweet> tweets=new List<Tweet>();


  TwitterManipulator() {
    _output = document.querySelector('#list');
    _readForm = document.querySelector('#read');
    _fileInput = document.querySelector('#files');
    _fileInput.onChange.listen((e) => _onFileInputChange());

    _dropZone = document.querySelector('#drop-zone');
    _dropZone.onDragOver.listen(_onDragOver);
    _dropZone.onDragEnter.listen((e) => _dropZone.classes.add('hover'));
    _dropZone.onDragLeave.listen((e) => _dropZone.classes.remove('hover'));
    _dropZone.onDrop.listen(_onDrop);
  }

  void _onDragOver(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  }

  void _onDrop(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
    _dropZone.classes.remove('hover');
    _readForm.reset();
    _onFilesSelected(event.dataTransfer.files);
  }

  void _onFileInputChange() {
    _onFilesSelected(_fileInput.files);
  }

  void _onFilesSelected(List<File> files) {
    var file=files.first;
    int startByte=0;
    int endByte=file.size;
    var start = startByte != null ? startByte : 0;
    var end = endByte != null ? endByte : file.size;
    var reader = new FileReader();
    var slice = file.slice(start, end);
    reader.onLoad.listen((event) => readStringCsv(reader.result));
    reader.readAsText(slice);
    }
  
  void readStringCsv(String csv){
    List<List> res = const CsvToListConverter().convert(csv,
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\n');
    print(res.length);
    for(List lst in res){
      tweets.add(new Tweet(lst[5]));
      print(tweets.last.isReply);
    }
  }
  
  }

class Tweet{
  String tweet;
  bool isReply;
  
  Tweet(String tweet){
    this.tweet=tweet;
    isReply=itIsReply(tweet);
  }
  
  bool itIsReply(String tweet){
    return tweet[0]=="@";
  }
  
}

void main() {
  new TwitterManipulator();
}