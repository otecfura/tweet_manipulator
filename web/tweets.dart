import 'dart:convert';
import 'dart:html';
import 'package:csv/csv.dart';

class TwitterManipulator {
  String TWEETS_LIST = "tweets";
  String tweetsJson;

  UListElement listOfNonSelected;
  UListElement listOfSelected;
  bool checkReply;
  bool checkRetweets;
  Element _dropZone;
  HtmlEscape sanitizer = new HtmlEscape();

  List<List> listOfTweets = null;
  List<Tweet> tweets = new List<Tweet>();
  List<Tweet> loadedTweets = new List<Tweet>();

  TwitterManipulator() {
    listOfNonSelected = document.querySelector('#to-do-list-nonselected');
    listOfSelected = document.querySelector('#to-do-list-selected');
    _dropZone = document.querySelector('#drop-zone');
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
    if (!isLocalData()) {
      _dropZone.onDragOver.listen(_onDragOver);
      _dropZone.onDragEnter.listen((e) => _dropZone.classes.add('hover'));
      _dropZone.onDragLeave.listen((e) => _dropZone.classes.remove('hover'));
      _dropZone.onDrop.listen(_onDrop);
    } else {
      _dropZone.hidden = true;
      loadFromLoacalStorage();
    }
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
    reader.readAsText(slice, "utf8");
  }

  void readStringCsv(String csv) {
    listOfTweets = const CsvToListConverter().convert(csv, fieldDelimiter: ',', textDelimiter: '"', textEndDelimiter: '"', eol: '\n');
    fillWithData();
  }

  void createSaveJson() {
    Map notesJsonMap = new Map();
    List notesJsonList = new List();

    for (Tweet tweet in tweets) {
      Map noteJsonMap = new Map();
      noteJsonMap["tweet"] = tweet.tweet;
      noteJsonMap["isReply"] = tweet.isReply;
      noteJsonMap["isRT"] = tweet.isRT;
      noteJsonMap["isSelected"] = tweet.isSelected;
      notesJsonList.add(noteJsonMap);
    }
    notesJsonMap["tweets"] = notesJsonList;
    tweetsJson = JSON.encode(notesJsonMap);
  }

  bool isLocalData() {
    return window.localStorage[TWEETS_LIST] != null;
  }

  void saveToLocalStorage() {
    createSaveJson();
    window.localStorage[TWEETS_LIST] = tweetsJson;
  }

  void loadFromLoacalStorage() {
    Map tweetsJsonMap = JSON.decode(window.localStorage[TWEETS_LIST]);
    List tweetsJsonList = tweetsJsonMap["tweets"];

    for (Map noteJsonMap in tweetsJsonList) {
      Tweet tweet = new Tweet();
      tweet.tweet = noteJsonMap["tweet"];
      tweet.isSelected = noteJsonMap["isSelected"];
      tweet.isRT = noteJsonMap["isRT"];
      tweet.isReply = noteJsonMap["isReply"];
      loadedTweets.add(tweet);
    }
    fillWithData();
  }

  void fillWithData() {
    listOfNonSelected.children.clear();
    listOfSelected.children.clear();
    tweets.clear();
    if (!isLocalData()) {
      if (listOfTweets != null) {
        for (List lst in listOfTweets) {
          if (lst != listOfTweets.first) {
            Tweet tweet = new Tweet.list(lst);
            addTweet(tweet);
          }
        }
      }
    } else {
      for (Tweet tweet in loadedTweets) {
        addTweet(tweet);
      }
    }
    saveToLocalStorage();
  }

  void addTweet(Tweet tweet) {
    tweets.add(tweet);
    var LiTweet = new LIElement();
    LiTweet.onClick.listen((event) => tweetSelect(LiTweet, tweet));
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
    if (tweet.isSelected) {
      listOfSelected.append(LiTweet);
    }
  }

  void tweetSelect(var LiTweet, Tweet tweet) {
    if (listOfNonSelected.children.contains(LiTweet)) {
      listOfNonSelected.children.remove(LiTweet);
      listOfSelected.append(LiTweet);
    } else {
      listOfSelected.children.remove(LiTweet);
      listOfNonSelected.append(LiTweet);
    }
    tweet.isSelected = !tweet.isSelected;
    saveToLocalStorage();
  }
}

class Tweet {
  String tweet;
  bool isReply;
  bool isRT;
  bool isSelected = false;

  Tweet() {
  }

  Tweet.list(List tweet) {
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
