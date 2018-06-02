/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2018/5/22 下午1:16
 */

import 'dart:async';
import 'package:flutter_gank/constant/colors.dart';
import 'package:flutter_gank/utils/utils_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gank/bean/info_gank.dart';
import 'package:flutter_gank/constant/strings.dart';
import 'package:flutter_gank/utils/utils_http.dart';
import 'package:flutter_gank/utils/utils_indicator.dart';
import 'package:flutter_gank/widget/cached_pic.dart';
import 'package:flutter_gank/widget/item_gank.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widget/CircleClipper.dart';
import 'package:flutter/scheduler.dart';

class GirlPage extends StatefulWidget {
  final bool isCard;

  GirlPage({this.isCard});

  @override
  _GirlPageState createState() => new _GirlPageState();
}

class _GirlPageState extends State<GirlPage>
    with IndicatorFactory, HttpUtils, DbUtils {
  List<GirlInfo> _dataList = [];

  RefreshController _refreshController;

  int _pageIndex = 1;

  ValueNotifier<double> offsetLis = new ValueNotifier(0.0);

  void _fetchMoreData() async {
    getGirlfromNet(URL_GANK_FETCH + "福利" + "/20/$_pageIndex")
        .then((List<GirlInfo> data) {
      if (data.isEmpty) {
        //空数据
        _refreshController.sendBack(false, RefreshStatus.noMore);
      } else {
        for (GirlInfo item in data) {
          _dataList.add(item);
          insert("Girl", item.toMap()).then((val) {});
        }

        _pageIndex++;

        _refreshController.sendBack(false, RefreshStatus.idle);
        setState(() {});
      }
      return false;
    }).catchError((error) {
      _refreshController.sendBack(false, 4);
      return false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _refreshController = new RefreshController();
    getList("Girl").then((List<dynamic> list) {
      if (list.isEmpty) {
        SharedPreferences.getInstance().then((SharedPreferences preferences) {
          if (preferences.getBool("autoRefresh") ?? false) {
            _fetchMoreData();
          }
        });
      } else {
        for (Map map in list) {
          _dataList.add(new GirlInfo.fromMap(map));
        }
        int aa = list.length ~/ 20;
        _pageIndex = aa + 1;
      }
    });
    super.initState();
  }


  void _onOffsetCall(bool up, double offset) {
    if (up) {
      offsetLis.value = offset;
    }
  }

  void _onRefresh(bool up) {
    if (!up) {
      //上拉加载
      _fetchMoreData();
    } else {
      new Future.delayed(const Duration(milliseconds: 1000)).then((val) {
        _refreshController.sendBack(true, RefreshStatus.completed);
      });
    }
  }

  void _onClickLike(int index) {
    _dataList[index].like = !_dataList[index].like;
    setState(() {

    });
    update("Girl", _dataList[index].toMap(), "id = ? ", [_dataList[index].id]);
  }

  Widget _buildList() {
    if (widget.isCard) {
      return new ListView.builder(
          itemCount: _dataList.length,
          itemBuilder: (context, index) => new GirlCardItem(
                who: _dataList[index].who,
                time: _dataList[index].desc,
                url: _dataList[index].url,
                isLike: _dataList[index].like,
                onChangeVal: () {
                  _onClickLike(index);
                },
              ));
    }
    return new StaggeredGridView.countBuilder(
      crossAxisCount: 6,
      itemCount: _dataList.length,
      itemBuilder: (context, index) => new CachedPic(
            url: _dataList[index].url,
          ),
      staggeredTileBuilder: (int index) =>
          new StaggeredTile.count(3, index.isEven ? 3 : 2),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
    );
  }

  @override
  void didUpdateWidget(GirlPage oldWidget) {
    // TODO: implement didUpdateWidget

    super.didUpdateWidget(oldWidget);
    getList("Girl").then((List<dynamic> list) {
        _dataList.clear();
        for (Map map in list) {
          _dataList.add(new GirlInfo.fromMap(map));
        }
        int aa = list.length ~/ 20;
        _pageIndex = aa + 1;
        setState(() {

        });
    });
    if (widget.isCard != oldWidget.isCard) {
      SchedulerBinding.instance.addPostFrameCallback((val) {
        _refreshController.scrollTo(0.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      new ArcIndicator(
        offsetLis: offsetLis,
      ),
      new Container(
        child: new SmartRefresher(
          controller: _refreshController,
          child: _buildList(),
          headerBuilder: buildDefaultHeader,
          footerBuilder: buildDefaultFooter,
          onRefresh: _onRefresh,
          enablePullUp: true,
          onOffsetChange: _onOffsetCall,
        ),
      )
    ]);
  }
}
