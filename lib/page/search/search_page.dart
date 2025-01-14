import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_drawer.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_input_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';

/**
 * 搜索页面
 * Created by guoshuyu
 * on 2018/7/24.
 */
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with
        AutomaticKeepAliveClientMixin<SearchPage>,
        GSYListState<SearchPage>,
        SingleTickerProviderStateMixin {
  ///搜索仓库还是人
  int selectIndex = 0;

  ///搜索文件
  String searchText;

  ///排序类型
  String type = searchFilterType[0].value;

  ///排序
  String sort = sortType[0].value;

  ///过滤语言
  String language = searchLanguageType[0].value;

  AnimationController controller;
  Animation animation;
  bool endAnima = false;

  ///绘制item
  _renderItem(index) {
    var data = pullLoadWidgetControl.dataList[index];
    if (selectIndex == 0) {
      ReposViewModel reposViewModel = ReposViewModel.fromMap(data);
      return new ReposItem(reposViewModel, onPressed: () {
        NavigatorUtils.goReposDetail(
            context, reposViewModel.ownerName, reposViewModel.repositoryName);
      });
    } else if (selectIndex == 1) {
      return new UserItem(UserItemViewModel.fromMap(data), onPressed: () {
        NavigatorUtils.goPerson(
            context, UserItemViewModel.fromMap(data).userName);
      });
    }
  }

  ///切换tab
  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  ///获取搜索数据
  _getDataLogic() async {
    return await ReposDao.searchRepositoryDao(searchText, language, type, sort,
        selectIndex == 0 ? null : 'user', page, Config.PAGE_SIZE);
  }

  ///清空过滤数据
  _clearSelect(List<FilterModel> list) {
    for (FilterModel model in list) {
      model.select = false;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => false;

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInCubic,
    )..addListener(() {
        setState(() {});
      });

    Future.delayed(new Duration(seconds: 0), () {
      controller.forward().then((_) {
        setState(() {
          endAnima = true;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _clearSelect(sortType);
    sortType[0].select = true;
    _clearSelect(searchLanguageType);
    searchLanguageType[0].select = true;
    _clearSelect(searchFilterType);
    searchFilterType[0].select = true;
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new Container(
      ///填充剩下半圆颜色
      color: endAnima ? Theme.of(context).primaryColor : Colors.transparent,
      child: CRAnimation(
        minR: MediaQuery.of(context).size.height - 8,
        maxR: 0,
        offset: Offset(MediaQuery.of(context).size.width - 50,
            MediaQuery.of(context).padding.top - 10),
        animation: animation,
        child: new Scaffold(
          resizeToAvoidBottomPadding: false,

          ///右侧 Drawer
          endDrawer: new GSYSearchDrawer(
            (String type) {
              ///排序类型
              this.type = type;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
            (String sort) {
              ///排序状态
              this.sort = sort;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
            (String language) {
              ///过滤语言
              this.language = language;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
          ),
          appBar: new AppBar(
              leading: IconButton(
                highlightColor: Colors.transparent,
                icon: const BackButtonIcon(),
                onPressed: () {
                  setState(() {
                    endAnima = false;
                  });
                  controller.reverse().then((_) {
                    Navigator.maybePop(context);
                  });
                },
              ),
              title: new Text(GSYLocalizations.i18n(context).search_title),
              bottom: new SearchBottom((value) {
                searchText = value;
              }, (value) {
                searchText = value;
                if (searchText == null || searchText.trim().length == 0) {
                  return;
                }
                if (isLoading) {
                  return;
                }
                _resolveSelectIndex();
              }, () {
                if (searchText == null || searchText.trim().length == 0) {
                  return;
                }
                if (isLoading) {
                  return;
                }
                _resolveSelectIndex();
              }, (selectIndex) {
                if (searchText == null || searchText.trim().length == 0) {
                  return;
                }
                if (isLoading) {
                  return;
                }
                this.selectIndex = selectIndex;
                _resolveSelectIndex();
              })),
          body: GSYPullLoadWidget(
            pullLoadWidgetControl,
            (BuildContext context, int index) => _renderItem(index),
            handleRefresh,
            onLoadMore,
            refreshKey: refreshIndicatorKey,
          ),
        ),
      ),
    );
  }
}

///实现 PreferredSizeWidget 实现自定义 appbar bottom 控件
class SearchBottom extends StatelessWidget implements PreferredSizeWidget {
  final SelectItemChanged onChanged;

  final SelectItemChanged onSubmitted;

  final SelectItemChanged selectItemChanged;

  final VoidCallback onSubmitPressed;

  SearchBottom(this.onChanged, this.onSubmitted, this.onSubmitPressed,
      this.selectItemChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GSYSearchInputWidget(onChanged, onSubmitted, onSubmitPressed),
        new GSYSelectItemWidget(
          [
            GSYLocalizations.i18n(context).search_tab_repos,
            GSYLocalizations.i18n(context).search_tab_user,
          ],
          selectItemChanged,
          elevation: 0.0,
          margin: const EdgeInsets.all(5.0),
        )
      ],
    );
  }

  @override
  Size get preferredSize {
    return new Size.fromHeight(100.0);
  }
}

class CRAnimation extends StatelessWidget {
  final Offset offset;

  final double minR;

  final double maxR;

  final Widget child;

  final Animation<double> animation;

  CRAnimation({
    @required this.child,
    @required this.animation,
    this.offset,
    this.minR,
    this.maxR,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return ClipPath(
          clipper: AnimationClipper(
            value: animation.value,
            minR: minR,
            maxR: maxR,
            offset: offset,
          ),
          child: this.child,
        );
      },
    );
  }
}

class AnimationClipper extends CustomClipper<Path> {
  final double value;

  final double minR;

  final double maxR;

  final Offset offset;

  AnimationClipper({
    this.value,
    this.offset,
    this.minR,
    this.maxR,
  });

  @override
  bool shouldReclip(old) => true;

  @override
  Path getClip(Size size) {
    var path = Path();
    var offset = this.offset ?? Offset(size.width / 2, size.height / 2);

    var maxRadius = minR ?? radiusSize(size, offset);

    var minRadius = maxR ?? 0;

    var radius = lerpDouble(minRadius, maxRadius, value);
    var rect = Rect.fromCircle(
      radius: radius,
      center: offset,
    );

    path.addOval(rect);
    return path;
  }

  double radiusSize(Size size, Offset offset) {
    final height = max(offset.dy, size.height - offset.dy);
    final width = max(offset.dx, size.width - offset.dx);
    return sqrt(width * width + height * height);
  }
}
