import 'dart:convert' show HtmlEscape;
import 'dart:html';
import 'package:csv/csv.dart';

class TwitterManipulator {
  List<List> listOfTweets = null;

  UListElement listOfNonSelected;
  UListElement listOfSelected;
  bool checkReply;
  bool checkRetweets;
  Element _dropZone;
  HtmlEscape sanitizer = new HtmlEscape();
  List<Tweet> tweets = new List<Tweet>();
  List<Word> orderedWords= new List<Word>();

  TwitterManipulator() {
    listOfNonSelected = document.querySelector('#to-do-list-nonselected');
    listOfSelected = document.querySelector('#to-do-list-selected');
    document.querySelector("#reply").onChange.listen((Event e) {
      bool checked = (e.currentTarget as InputElement).checked;
      checkReply = checked;
      fillWithData();
    });
    document.querySelector("#retweets").onChange.listen((Event e) {
      bool checked = (e.currentTarget as InputElement).checked;
      checkRetweets = checked;
      fillWithData();
    });
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
    var file = files.first;
    int startByte = 0;
    int endByte = file.size;
    var start = startByte != null ? startByte : 0;
    var end = endByte != null ? endByte : file.size;
    var reader = new FileReader();
    var slice = file.slice(start, end);
    reader.onLoad.listen((event) => readStringCsv(reader.result));
    reader.readAsText(slice);
  }

  void readStringCsv(String csv) {
    listOfTweets = const CsvToListConverter().convert(csv, fieldDelimiter: ',', textDelimiter: '"', textEndDelimiter: '"', eol: '\n');
    fillWithData();
  }

  void countWords() {
    if (tweets.isNotEmpty) {
      for (Tweet tweet in tweets) {
        var tweetString = tweet.tweet;
        tweetString = tweetString.toLowerCase();
        tweetString = tweetString.replaceAll(new RegExp('[.,;!?#"]'), ' ');
        tweetString = tweetString.replaceAll(new RegExp('\@\S+'), ' ');
        List<String> words = tweetString.split(' ');
        for (String word in words) {
          Word tested=null;
          word = word.trim();
          bool test = orderedWords.any((m) {
            bool isExists = m.word == word;
            if(isExists){
              tested=m;
            }
            return isExists;
          });
          if(test){
            tested.count=tested.count+1;
          }else{
            orderedWords.add(new Word(word));
          }
        }
      }

  }
    orderedWords.sort();
    for(Word wo in orderedWords.sublist(0,100)){
      print(wo.word);
      print(wo.count);
    }
    
  }

  void fillWithData() {
    listOfNonSelected.children.clear();
    listOfSelected.children.clear();
    tweets.clear();
    if (listOfTweets != null) {
      for (List lst in listOfTweets) {
        if (lst != listOfTweets.first) {
          Tweet tweet = new Tweet(lst);
          tweets.add(tweet);
          var LiTweet = new LIElement();
          LiTweet.onClick.listen((event) => tweetSelect(LiTweet));
          LiTweet.text = tweet.tweet;

          if (!tweet.isRT && !tweet.isReply) {
            listOfNonSelected.append(LiTweet);
          }
          if (tweet.isReply && checkReply) {
            listOfNonSelected.append(LiTweet);
          }
          if (tweet.isRT && checkRetweets) {
            listOfNonSelected.append(LiTweet);
          }
        }
      }
    }
    countWords();
  }

  void tweetSelect(var LiTweet) {
    if (listOfNonSelected.children.contains(LiTweet)) {
      listOfNonSelected.children.remove(LiTweet);
      listOfSelected.append(LiTweet);
    } else {
      listOfSelected.children.remove(LiTweet);
      listOfNonSelected.append(LiTweet);
    }
  }
}

class Word{
  String word;
  int count;
  
  Word(String word) {
    this.word = word;
    count=1;
  }
  
  int compareTo(Word other){
    if(other.count>count){
      return 1;
    }
    if(other.count<count){
     return -1; 
    }
     return 0; 
  }
  
}

class Tweet {
  String tweet;
  bool isReply;
  bool isRT;
  bool isSelected;

  Tweet(List tweet) {
    this.tweet = tweet[5];
    isReply = itIsReply(this.tweet);
    isRT = itIsRT(tweet);
  }

  void setIsSelected(bool isSelected) {
    this.isSelected = isSelected;
  }

  bool itIsReply(String tweet) {
    return tweet[0] == "@";
  }

  bool itIsRT(List tweet) {
    bool RT = false;
    if (tweet[5].substring(0, 2) == "RT") {
      RT = true;
    }
    if (tweet[7] != "") {
      RT = true;
    }
    return RT;
  }

}

void main() {
  new TwitterManipulator();
}
