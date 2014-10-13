import 'dart:convert' show HtmlEscape;
import 'dart:html';
import 'package:csv/csv.dart';

class TwitterManipulator {
  UListElement listOfNonSelected;
  UListElement listOfSelected;
  Element _dropZone;
  HtmlEscape sanitizer = new HtmlEscape();
  List<Tweet> tweets=new List<Tweet>();


  TwitterManipulator() {
    listOfNonSelected = document.querySelector('#to-do-list-nonselected');
    listOfSelected = document.querySelector('#to-do-list-selected');
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
    _onFilesSelected(event.dataTransfer.files);
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
    for(List lst in res){
      tweets.add(new Tweet(lst[5]));
      if(lst!=res.first){
        var LiTweet=new LIElement();
        LiTweet.text=lst[5];
        listOfNonSelected.append(LiTweet);
      }
    }
  }
  
  }

class Tweet{
  String tweet;
  bool isReply;
  bool isSelected;
  
  Tweet(String tweet){
    this.tweet=tweet;
    isReply=itIsReply(tweet);
  }
  
  void setIsSelected(bool isSelected){
    this.isSelected=isSelected;
  }
  
  bool itIsReply(String tweet){
    return tweet[0]=="@";
  }
  
}

void main() {
  new TwitterManipulator();
}