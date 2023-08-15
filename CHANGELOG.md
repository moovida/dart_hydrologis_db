## 1.1.0

- Moved to abstract queryresult api. 

## 1.0.1

- better support for asian table names
- fixes in postgres error rethrowing

## 1.0.0+1

- fix on sqlite primary key retrival

## 1.0.0

- added support for schemas (postgres)
- breaking changes on SqlName

## 0.7.4

- postgres libs upgrade
- added more options for db open

## 0.7.3

- major sqlite upgrade.

## 0.7.2

- added returning of generated ids also for postgres.

## 0.7.1

- added conditional imports to work on web without the sqlite3 part.
## 0.7.0

- libraries upgrade
- migrate to null safety

## 0.6.2

- fix for mbtiles metadata reading bug.

## 0.6.1

- deps libs upgrade.

## 0.6.0

- Force the error debug message to be completed with Exception adn Stacktrace.

## 0.5.1

- QueryObjectBuilder method change to reflect new api and avoid downstream confusion.

## 0.5.0

- add first simple postgresql support.

## 0.4.1

- add notnull to table column info.

## 0.4.0

- ad SqlName utility class to make safe name usage easier. This breaks compatibility.

## 0.3.1

- add table name escaping utility

## 0.3.0

- remove deprecated moor_ffi and migrate to suggested sqlite3.
- bring function creation to module.

## 0.2.1+1

- added datatypes utility

## 0.2.1

- add of mbtiles db type.

## 0.2.0

- Use moor 0.7.0 to allow android rtree to be used.

## 0.1.0

- Initial version, a wrapper to make sqlite handling simpler and have a set of testcases to build on.
