library model;

import 'package:pritunl/exceptions.dart';
import 'package:pritunl/model.dart' as mdl;

import 'package:angular/angular.dart' as ng;
import 'dart:mirrors' as mirrors;
import 'dart:collection' as collection;
import 'dart:async' as async;
import 'dart:math' as math;

class Collection extends collection.IterableBase {
  List<mdl.Model> _collection;
  int _loadCheckId;
  ng.Http http;
  String url;
  Type model;
  int errorStatus;
  dynamic errorData;
  bool loadingLong;

  var _loading;
  set loading(bool val) {
    if (val) {
      var loadCheckId = new math.Random().nextInt(32000);
      this._loadCheckId = loadCheckId;
      this._loading = true;

      new async.Future.delayed(
        const Duration(milliseconds: 200), () {
          if (this._loadCheckId == loadCheckId) {
            this.loadingLong = true;
          }
        });
    }
    else {
      this._loadCheckId = null;
      this.loadingLong = false;
      this._loading = false;
    }
  }
  bool get loading {
    return this._loading;
  }

  Collection(this.http) : _collection = [];

  Iterator get iterator {
    return this._collection.iterator;
  }

  async.Future fetch() {
    this.loading = true;

    return this.http.get(this.url).then((response) {
      this.loading = false;
      this.import(response.data);
      return response.data;
    }).catchError((err) {
      this.loading = false;
      this.errorStatus = err.status;
      this.errorData = err.data;
      throw err;
    });
  }

  dynamic parse(dynamic data) {
    return data;
  }

  void import(dynamic responseData) {
    var data;

    try {
      data = this.parse(responseData);
    } on IgnoreResponse {
      return;
    }

    var modelCls = mirrors.reflectClass(this.model);
    var initSym = const Symbol('');
    this._collection = [];

    data.forEach((value) {
      var mdl = modelCls.newInstance(initSym, [this.http]).reflectee;
      mdl.import(value);
      this._collection.add(mdl);
    });

    this.imported();
  }

  void imported() {
  }

  void save() {
  }
}
