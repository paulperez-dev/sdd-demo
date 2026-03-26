// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_dao.dart';

// ignore_for_file: type=lint
mixin _$UrlDaoMixin on DatabaseAccessor<AppDatabase> {
  $UrlsTable get urls => attachedDatabase.urls;
  UrlDaoManager get managers => UrlDaoManager(this);
}

class UrlDaoManager {
  final _$UrlDaoMixin _db;
  UrlDaoManager(this._db);
  $$UrlsTableTableManager get urls =>
      $$UrlsTableTableManager(_db.attachedDatabase, _db.urls);
}
