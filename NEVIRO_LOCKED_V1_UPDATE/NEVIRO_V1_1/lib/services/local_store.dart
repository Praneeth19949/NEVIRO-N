import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/fuel_entry.dart';
import '../models/money_transaction.dart';
import '../models/station_price.dart';

class LocalStore extends ChangeNotifier {
  static const _entriesKey='neviro.entries.v1', _regionKey='neviro.region.v1', _currencyKey='neviro.currency.v1', _distanceUnitKey='neviro.distanceUnit.v1', _efficiencyUnitKey='neviro.efficiencyUnit.v1', _cheapestKey='neviro.cheapest.v1', _cheapestAreaKey='neviro.cheapestArea.v1', _cheapestUpdatedKey='neviro.cheapestUpdated.v1';
  static const _transactionsKey='neviro.transactions.v2', _budgetsKey='neviro.budgets.v2', _setupKey='neviro.setupComplete.v2';

  final SharedPreferences preferences;
  final List<FuelEntry> entries;
  final List<MoneyTransaction> transactions;
  final List<Budget> budgets;
  String regionOverride;
  String? currencyOverride;
  String distanceUnit;
  String efficiencyUnit;
  bool setupComplete;
  StationPrice? cachedCheapest;
  String? cachedCheapestArea;
  DateTime? cachedCheapestUpdated;

  LocalStore({required this.preferences,required this.entries,required this.transactions,required this.budgets,required this.regionOverride,required this.currencyOverride,required this.distanceUnit,required this.efficiencyUnit,required this.setupComplete,required this.cachedCheapest,required this.cachedCheapestArea,required this.cachedCheapestUpdated});

  static Future<LocalStore> load() async {
    final prefs=await SharedPreferences.getInstance();
    List<T> decodeList<T>(String key,T Function(Map<String,dynamic>) make){
      final out=<T>[]; final raw=prefs.getString(key); if(raw==null)return out;
      try{final d=jsonDecode(raw); if(d is List){for(final x in d){if(x is Map)out.add(make(Map<String,dynamic>.from(x)));}}}catch(_){}
      return out;
    }
    final entries=decodeList(_entriesKey,FuelEntry.fromJson)..sort((a,b)=>b.date.compareTo(a.date));
    final tx=decodeList(_transactionsKey,MoneyTransaction.fromJson)..sort((a,b)=>b.date.compareTo(a.date));
    final budgets=decodeList(_budgetsKey,Budget.fromJson);
    StationPrice? cheapest; final cr=prefs.getString(_cheapestKey); if(cr!=null){try{final d=jsonDecode(cr); if(d is Map)cheapest=StationPrice.fromJson(Map<String,dynamic>.from(d));}catch(_){}}
    return LocalStore(preferences:prefs,entries:entries,transactions:tx,budgets:budgets,regionOverride:prefs.getString(_regionKey)??'AUTO',currencyOverride:prefs.getString(_currencyKey),distanceUnit:prefs.getString(_distanceUnitKey)??'km',efficiencyUnit:prefs.getString(_efficiencyUnitKey)??'L/100km',setupComplete:prefs.getBool(_setupKey)??false,cachedCheapest:cheapest,cachedCheapestArea:prefs.getString(_cheapestAreaKey),cachedCheapestUpdated:DateTime.tryParse(prefs.getString(_cheapestUpdatedKey)??''));
  }
  Future<void> _saveEntries()=>preferences.setString(_entriesKey,jsonEncode(entries.map((e)=>e.toJson()).toList()));
  Future<void> _saveTx()=>preferences.setString(_transactionsKey,jsonEncode(transactions.map((e)=>e.toJson()).toList()));
  Future<void> _saveBudgets()=>preferences.setString(_budgetsKey,jsonEncode(budgets.map((e)=>e.toJson()).toList()));

  Future<void> completeSetup(String country,String currency) async {regionOverride=country;currencyOverride=currency;setupComplete=true;await preferences.setString(_regionKey,country);await preferences.setString(_currencyKey,currency);await preferences.setBool(_setupKey,true);notifyListeners();}
  Future<void> addTransaction(MoneyTransaction t) async {transactions.add(t);transactions.sort((a,b)=>b.date.compareTo(a.date));await _saveTx();notifyListeners();}
  Future<void> deleteTransaction(String id) async {transactions.removeWhere((e)=>e.id==id);await _saveTx();notifyListeners();}
  Future<void> setBudget(String category,double limit) async {budgets.removeWhere((b)=>b.category==category);if(limit>0)budgets.add(Budget(category:category,monthlyLimit:limit));await _saveBudgets();notifyListeners();}
  double budgetFor(String category)=>budgets.where((b)=>b.category==category).fold(0.0,(s,b)=>s+b.monthlyLimit);

  Future<void> addEntry(FuelEntry entry) async {entries.add(entry);entries.sort((a,b)=>b.date.compareTo(a.date));await _saveEntries(); final exists=transactions.any((t)=>t.linkedFuelEntryId==entry.id); if(!exists){await addTransaction(MoneyTransaction(id:'fuel-${entry.id}',date:entry.date,type:MoneyTransactionType.expense,category:'Fuel',description:entry.station.isEmpty?'Fuel fill-up':entry.station,amount:entry.total,notes:entry.notes,linkedFuelEntryId:entry.id));}notifyListeners();}
  Future<void> updateEntry(FuelEntry entry) async {final i=entries.indexWhere((e)=>e.id==entry.id);if(i<0)return;entries[i]=entry;entries.sort((a,b)=>b.date.compareTo(a.date));await _saveEntries();final ti=transactions.indexWhere((t)=>t.linkedFuelEntryId==entry.id);if(ti>=0){transactions[ti]=MoneyTransaction(id:transactions[ti].id,date:entry.date,type:MoneyTransactionType.expense,category:'Fuel',description:entry.station.isEmpty?'Fuel fill-up':entry.station,amount:entry.total,notes:entry.notes,linkedFuelEntryId:entry.id);await _saveTx();}notifyListeners();}
  Future<void> deleteEntry(String id) async {entries.removeWhere((e)=>e.id==id);transactions.removeWhere((t)=>t.linkedFuelEntryId==id);await _saveEntries();await _saveTx();notifyListeners();}
  Future<void> clearAllData() async {entries.clear();transactions.clear();budgets.clear();await _saveEntries();await _saveTx();await _saveBudgets();notifyListeners();}
  Future<void> setRegionOverride(String v) async {regionOverride=v;await preferences.setString(_regionKey,v);notifyListeners();}
  Future<void> setCurrencyOverride(String? v) async {currencyOverride=v;if(v==null)await preferences.remove(_currencyKey);else await preferences.setString(_currencyKey,v);notifyListeners();}
  Future<void> setDistanceUnit(String v) async {distanceUnit=v;await preferences.setString(_distanceUnitKey,v);notifyListeners();}
  Future<void> setEfficiencyUnit(String v) async {efficiencyUnit=v;await preferences.setString(_efficiencyUnitKey,v);notifyListeners();}
  Future<void> cacheCheapest({required StationPrice station,required String area}) async {cachedCheapest=station;cachedCheapestArea=area;cachedCheapestUpdated=DateTime.now();await preferences.setString(_cheapestKey,jsonEncode(station.toJson()));await preferences.setString(_cheapestAreaKey,area);await preferences.setString(_cheapestUpdatedKey,cachedCheapestUpdated!.toIso8601String());notifyListeners();}
}
