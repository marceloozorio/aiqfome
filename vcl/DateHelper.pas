unit DateHelper;

interface
uses
  DateUtils,
  SysUtils,
  {$IFDEF VER150}
  Controls,
  {$ENDIF}
  Types,
  StringFunctions,
  SerializableObjects;

type
  TDateTimeObject = class;

  tpDateTime = (td_year, td_month, td_day, td_hour, td_minute, td_second, td_millisecond, td_timezone,td_none);
  tLookupDate =  array[tpDateTime] of string;
  tLookupDateTime = array[tpDateTime] of word;

  TDateHelper = class
  private
    class function convertFrom(chr: string): tpDateTime;
    class procedure loadLookupValues(year, month, day, hour, minute, second: Word; millisecond: LongWord; timeZone: integer; var lookup: tLookupDateTime);
    class procedure loadValues(var year, month, day, hour, minute, second :Word; var millisecond: LongWord; var timeZone: integer; lookup: tLookupDate);
    class function processValue(lookup: tLookupDateTime; lookupMask: tLookupDate; tpDate: tpDateTime): string;
    class function normalizeValue(formatedValue: string; lookupMask: tLookupDate; value: integer; type_date: tpDateTime): string;
    class procedure normalize(var year, month, day: word);
    class function Match(lookup: tLookupDateTime; lookupMask: tLookupDate): tLookupDate;
  public
    class function decode(format: string; value: string): TDateTimeObject;
    class function formatDateTime(format: string; date: TDateTime; timeZone: integer): string;
    class function diff(value1, value2: TDateTimeObject): TDateTimeObject;
    class procedure inc(dateTimeObject: TDateTimeObject; incValue: integer; tp_DateTime: tpDateTime);
  end;

  TDateTimeObject = class(TCustomPersistent)
  private
    Fvalue: TDateTime;
    procedure Setvalue(const Value: TDateTime);
    function TryParse(format, value: String): TDateTimeObject;
  public
    format: string;
    format2: String;
    timeZone: integer;
    constructor create(format: string; timeZone: integer);
    class function newInstance: TCustomPersistent; reintroduce; overload; override;
    procedure assign(source: TDateTimeObject);
    procedure loadFrom(value: string);
    class procedure setDateFormat(format: string);
    class function getDateFormat: string;
    function formatDateTime: string; overload;
    function formatDateTime(format: string): string; overload;
    procedure refresh;
    class function getTimeZone: integer;
    class procedure setTimeZone(timeZone: integer);
    procedure inc(incValue: integer; tp_DateTime: tpDateTime);
    function diff(datetime: TDateTimeObject): TDateTimeObject;
    function isBetween(date1, date2: TDateTime): boolean; overload;
    function dateIsBetween(date1, date2: TDate): boolean; overload;
    function timeIsBetween(date1, date2: TTime): boolean; overload;
    function dateIsBetween(date1, date2: TDateTimeObject): boolean; overload;
    function timeIsBetween(date1, date2: TDateTimeObject): boolean; overload;
    function isBetween(date1, date2: TDateTimeObject): boolean; overload;
    function dateOf: TDate;
    function timeOf: TTime;
    function YearOf: Word;
    function MonthOf: Word;
    function WeekOf: Word;
    function DayOf: Word;
    function HourOf: Word;
    function MinuteOf: Word;
    function SecondOf: Word;
    function MilliSecondOf: Word;

    function StartOfTheYear: TDateTime;
    function EndOfTheYear: TDateTime;
    function StartOfAYear: TDateTime;
    function EndOfAYear: TDateTime;

    function StartOfTheMonth: TDateTime;
    function EndOfTheMonth: TDateTime;
    function StartOfAMonth: TDateTime;
    function EndOfAMonth: TDateTime;

    function StartOfTheWeek: TDateTime;
    function EndOfTheWeek: TDateTime;
    function StartOfAWeek: TDateTime;
    function EndOfAWeek: TDateTime;


    function StartOfTheDay: TDateTime;
    function EndOfTheDay: TDateTime;
    function StartOfADayOfTheYear: TDateTime;
    function EndOfADayOfMonth: TDateTime;
    function StartOfADayOfTheMonth: TDateTime;
    function EndOfADayOfYear: TDateTime;

    function MonthOfTheYear: Word;
    function WeekOfTheYear: Word;
    function DayOfTheYear: Word;
    function HourOfTheYear: Word;
    function MinuteOfTheYear: LongWord;
    function SecondOfTheYear: LongWord;
    function MilliSecondOfTheYear: Int64;

    function WeekOfTheMonth: Word;
    function DayOfTheMonth: Word;
    function HourOfTheMonth: Word;
    function MinuteOfTheMonth: Word;
    function SecondOfTheMonth: LongWord;
    function MilliSecondOfTheMonth: LongWord;

    function DayOfTheWeek: Word;
    function HourOfTheWeek: Word;
    function MinuteOfTheWeek: Word;
    function SecondOfTheWeek: LongWord;
    function MilliSecondOfTheWeek: LongWord;

    function HourOfTheDay: Word;
    function MinuteOfTheDay: Word;
    function SecondOfTheDay: LongWord;
    function MilliSecondOfTheDay: LongWord;

    function MinuteOfTheHour: Word;
    function SecondOfTheHour: Word;
    function MilliSecondOfTheHour: LongWord;

    function SecondOfTheMinute: Word;
    function MilliSecondOfTheMinute: LongWord;

    function MilliSecondOfTheSecond: Word;

    procedure EncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word);
    procedure DecodeDateTime(out AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word);

    function CompareDateTime(const value: TDateTime): TValueRelationship;
    function SameDateTime(const value: TDateTime): Boolean;
    function CompareDate(const value: TDateTime): TValueRelationship;
    function SameDate(const value: TDateTime): Boolean;
    function CompareTime(const value: TDateTime): TValueRelationship;
    function SameTime(const value: TDateTime): Boolean;

    function TryEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;
    function TryEncodeDateWeek(const AYear, AWeekOfYear: Word; const ADayOfWeek: Word = 1): Boolean;
    function TryEncodeDateDay(const AYear, ADayOfYear: Word): Boolean;
    function TryEncodeDateMonthWeek(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word): Boolean;

  published
    property value: TDateTime read Fvalue write Setvalue;
  end;

implementation

{ TDateTimeObject }



constructor TDateTimeObject.create(format: string; timeZone: integer);
begin
  inherited create;
  self.format:=format;
  Self.format2:='';
  self.value:=0;
  self.timeZone:=timeZone;
end;

class function TDateTimeObject.newInstance: TCustomPersistent;
begin
  Result:=TDateTimeObject.create(TDateTimeObject.getDateFormat, TDateTimeObject.getTimeZone);
end;

function TDateTimeObject.formatDateTime(format: string): string;
var dateHelper: TDateHelper;
begin
  if trim(format)='' then begin
    format:=TDateTimeObject.getDateFormat;
  end;
  dateHelper:=TDateHelper.create;
  Result:=dateHelper.formatDateTime(format, self.value, self.timeZone);
  dateHelper.Free;
end;

function TDateTimeObject.formatDateTime: string;
begin
  Result:=self.formatDateTime(self.format);
end;

function TDateTimeObject.TryParse(format, value: String): TDateTimeObject;
var val: string;
begin
  try
    val:=padRight(value, '0', length(format));
    Result:=TDateHelper.decode(format, val);
  except
    on e: Exception do begin
      Result:=nil;
    end;
  end;
end;

procedure TDateTimeObject.loadFrom(value: string);
var dateTimeObject: TDateTimeObject;
begin
  if trim(self.format)='' then begin
    raise Exception.create('Formato para a data não foi informado na classe TDateTimeObject - Método executado TDateTimeObject.loadFrom');
  end;
  dateTimeObject:=self.TryParse(Self.format, value);
  if dateTimeObject=nil then begin
    if Trim(Self.format2)<>'' then begin
      dateTimeObject:=self.TryParse(Self.format2, value);
    end;
  end;
  if dateTimeObject=nil then begin
    raise Exception.create('Erro ao decodificar data ' + value + ' do objeto ' + self.name);
  end;
  self.Fvalue:=dateTimeObject.value;
  self.timeZone:=dateTimeObject.timeZone;
  dateTimeObject.Free;
end;

procedure TDateTimeObject.Setvalue(const Value: TDateTime);
begin
  Fvalue := Value;
end;

var dateFormat: string;
class function TDateTimeObject.getDateFormat: string;
begin
  Result:=dateFormat;
end;

class procedure TDateTimeObject.setDateFormat(format: string);
begin
  dateFormat:=format;
end;

var timeZoneValue: integer;
class function TDateTimeObject.getTimeZone: integer;
begin
  Result:=timeZoneValue;
end;

class procedure TDateTimeObject.setTimeZone(timeZone: integer);
begin
  timeZoneValue:=timeZone;
end;

procedure TDateTimeObject.inc(incValue: integer; tp_DateTime: tpDateTime);
begin
  TDateHelper.inc(self, incValue, tp_DateTime);
end;

function TDateTimeObject.StartOfTheMonth: TDateTime;
begin
  Result:=DateUtils.StartOfTheMonth(self.value);
end;

function TDateTimeObject.EndOfAMonth: TDateTime;
begin
  Result:=DateUtils.EndOfAMonth(self.YearOf, self.MonthOf);
end;

function TDateTimeObject.EndOfTheMonth: TDateTime;
begin
  Result:=DateUtils.EndOfTheMonth(self.value);
end;

function TDateTimeObject.StartOfAMonth: TDateTime;
begin
  Result:=DateUtils.StartOfAMonth(self.YearOf, self.MonthOf);
end;

function TDateTimeObject.StartOfTheYear: TDateTime;
begin
  Result:=DateUtils.StartOfTheYear(self.value);
end;

function TDateTimeObject.StartOfAYear: TDateTime;
begin
  Result:=DateUtils.StartOfAYear(self.YearOf);
end;

function TDateTimeObject.EndOfAYear: TDateTime;
begin
  Result:=DateUtils.EndOfAYear(self.YearOf);
end;

function TDateTimeObject.EndOfTheYear: TDateTime;
begin
  Result:=DateUtils.EndOfTheYear(self.value);
end;

function TDateTimeObject.DayOf: Word;
begin
  Result:=DateUtils.DayOf(self.value);
end;

function TDateTimeObject.HourOf: Word;
begin
  Result:=DateUtils.HourOf(self.value);
end;

function TDateTimeObject.MilliSecondOf: Word;
begin
  Result:=DateUtils.MilliSecondOf(self.value);
end;

function TDateTimeObject.MinuteOf: Word;
begin
  Result:=DateUtils.MinuteOf(self.value);
end;

function TDateTimeObject.MonthOf: Word;
begin
  Result:=DateUtils.MonthOf(self.value);
end;

function TDateTimeObject.SecondOf: Word;
begin
  Result:=DateUtils.SecondOf(self.value);
end;

function TDateTimeObject.WeekOf: Word;
begin
  Result:=DateUtils.WeekOf(self.value);
end;

function TDateTimeObject.YearOf: Word;
begin
  Result:=DateUtils.YearOf(self.value);
end;

function TDateTimeObject.StartOfTheWeek: TDateTime;
begin
  Result:=DateUtils.StartOfTheWeek(self.value);
end;

function TDateTimeObject.EndOfAWeek: TDateTime;
begin
  Result:=DateUtils.EndOfAWeek(self.YearOf, self.WeekOf);
end;

function TDateTimeObject.EndOfTheWeek: TDateTime;
begin
  Result:=DateUtils.EndOfTheWeek(self.value);
end;

function TDateTimeObject.StartOfAWeek: TDateTime;
begin
  Result:=DateUtils.StartOfAWeek(self.YearOf, self.WeekOf);
end;

function TDateTimeObject.StartOfTheDay: TDateTime;
begin
  Result:=DateUtils.StartOfTheDay(self.value);
end;

function TDateTimeObject.EndOfADayOfMonth: TDateTime;
begin
  Result:=DateUtils.EndOfADay(self.YearOf, self.MonthOf, self.DayOf);
end;

function TDateTimeObject.EndOfADayOfYear: TDateTime;
begin
  Result:=DateUtils.EndOfADay(self.YearOf, self.DayOfTheYear);
end;

function TDateTimeObject.EndOfTheDay: TDateTime;
begin
  Result:=DateUtils.EndOfTheDay(self.value);
end;

function TDateTimeObject.StartOfADayOfTheMonth: TDateTime;
begin
  Result:=DateUtils.StartOfADay(self.YearOf, self.MonthOf, self.DayOf);
end;

function TDateTimeObject.StartOfADayOfTheYear: TDateTime;
begin
  Result:=DateUtils.StartOfADay(self.YearOf, self.DayOfTheYear);
end;

function TDateTimeObject.DayOfTheYear: Word;
begin
  Result:=DateUtils.DayOfTheYear(self.value);
end;

function TDateTimeObject.HourOfTheYear: Word;
begin
  Result:=DateUtils.HourOfTheYear(self.value);
end;

function TDateTimeObject.MilliSecondOfTheYear: Int64;
begin
  Result:=DateUtils.MilliSecondOfTheYear(self.value);
end;

function TDateTimeObject.MinuteOfTheYear: LongWord;
begin
  Result:=DateUtils.MinuteOfTheYear(self.value);
end;

function TDateTimeObject.MonthOfTheYear: Word;
begin
  Result:=DateUtils.MonthOfTheYear(self.value);  
end;

function TDateTimeObject.SecondOfTheYear: LongWord;
begin
  Result:=DateUtils.SecondOfTheYear(self.value);
end;

function TDateTimeObject.WeekOfTheYear: Word;
begin
  Result:=DateUtils.WeekOfTheYear(self.value);
end;

function TDateTimeObject.DayOfTheMonth: Word;
begin
  Result:=DateUtils.DayOfTheMonth(self.value);
end;

function TDateTimeObject.HourOfTheMonth: Word;
begin
  Result:=DateUtils.HourOfTheMonth(self.value);
end;

function TDateTimeObject.MilliSecondOfTheMonth: LongWord;
begin
  Result:=DateUtils.MilliSecondOfTheMonth(self.value);
end;

function TDateTimeObject.MinuteOfTheMonth: Word;
begin
  Result:=DateUtils.MinuteOfTheMonth(self.value);
end;

function TDateTimeObject.SecondOfTheMonth: LongWord;
begin
  Result:=DateUtils.SecondOfTheMonth(self.value);
end;

function TDateTimeObject.WeekOfTheMonth: Word;
begin
  Result:=DateUtils.WeekOfTheMonth(self.value);
end;

function TDateTimeObject.DayOfTheWeek: Word;
begin
  Result:=DateUtils.DayOfTheWeek(self.value);
end;

function TDateTimeObject.HourOfTheDay: Word;
begin
  Result:=DateUtils.HourOfTheDay(self.value);
end;

function TDateTimeObject.HourOfTheWeek: Word;
begin
  Result:=DateUtils.HourOfTheWeek(self.value);
end;

function TDateTimeObject.MilliSecondOfTheDay: LongWord;
begin
  Result:=DateUtils.MilliSecondOfTheDay(self.value);
end;

function TDateTimeObject.MilliSecondOfTheHour: LongWord;
begin
  Result:=DateUtils.MilliSecondOfTheHour(self.value);
end;

function TDateTimeObject.MilliSecondOfTheMinute: LongWord;
begin
  Result:=DateUtils.MilliSecondOfTheMinute(self.value);
end;

function TDateTimeObject.MilliSecondOfTheSecond: Word;
begin
  Result:=DateUtils.MilliSecondOfTheSecond(self.value);
end;

function TDateTimeObject.MilliSecondOfTheWeek: LongWord;
begin
  Result:=DateUtils.MilliSecondOfTheWeek(self.value);
end;

function TDateTimeObject.MinuteOfTheDay: Word;
begin
  Result:=DateUtils.MinuteOfTheDay(self.value);
end;

function TDateTimeObject.MinuteOfTheHour: Word;
begin
  Result:=DateUtils.MinuteOfTheHour(self.value);
end;

function TDateTimeObject.MinuteOfTheWeek: Word;
begin
  Result:=DateUtils.MinuteOfTheWeek(self.value);
end;

function TDateTimeObject.SecondOfTheDay: LongWord;
begin
  Result:=DateUtils.SecondOfTheDay(self.value);
end;

function TDateTimeObject.SecondOfTheHour: Word;
begin
  Result:=DateUtils.SecondOfTheHour(self.value);
end;

function TDateTimeObject.SecondOfTheMinute: Word;
begin
  Result:=DateUtils.SecondOfTheMinute(self.value);
end;

function TDateTimeObject.SecondOfTheWeek: LongWord;
begin
  Result:=DateUtils.SecondOfTheWeek(self.value);
end;

procedure TDateTimeObject.DecodeDateTime(out AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  DateUtils.DecodeDateTime(self.value, AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
end;

procedure TDateTimeObject.EncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  self.value:=DateUtils.EncodeDateTime(AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
end;

function TDateTimeObject.CompareDate(const value: TDateTime): TValueRelationship;
begin
  Result:=DateUtils.CompareDate(self.value, value);
end;

function TDateTimeObject.CompareDateTime(const value: TDateTime): TValueRelationship;
begin
  Result:=DateUtils.CompareDateTime(self.value, value);
end;

function TDateTimeObject.CompareTime(const value: TDateTime): TValueRelationship;
begin
  Result:=DateUtils.CompareTime(self.value, value);
end;

function TDateTimeObject.SameDate(const value: TDateTime): Boolean;
begin
  Result:=DateUtils.SameDate(self.value, value);
end;

function TDateTimeObject.SameDateTime(const value: TDateTime): Boolean;
begin
  Result:=DateUtils.SameDateTime(self.value, value);
end;

function TDateTimeObject.SameTime(const value: TDateTime): Boolean;
begin
  Result:=DateUtils.SameTime(self.value, value);
end;

function TDateTimeObject.TryEncodeDateDay(const AYear, ADayOfYear: Word): Boolean;
begin
  Result:=DateUtils.TryEncodeDateDay(AYear, ADayOfYear, self.Fvalue);
end;

function TDateTimeObject.TryEncodeDateMonthWeek(const AYear, AMonth, AWeekOfMonth, ADayOfWeek: Word): Boolean;
begin
  Result:=DateUtils.TryEncodeDateMonthWeek(AYear, AMonth, AWeekOfMonth, ADayOfWeek, self.Fvalue);
end;

function TDateTimeObject.TryEncodeDateTime(const AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word): Boolean;
begin
  Result:=DateUtils.TryEncodeDateTime(AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond, self.Fvalue);
end;

function TDateTimeObject.TryEncodeDateWeek(const AYear, AWeekOfYear, ADayOfWeek: Word): Boolean;
begin
  Result:=DateUtils.TryEncodeDateWeek(AYear, AWeekOfYear, self.Fvalue, ADayOfWeek);
end;

function TDateTimeObject.isBetween(date1, date2: TDateTime): boolean;
begin
  Result:=(dateUtils.CompareDateTime(self.value, date1)>=0) and (DateUtils.CompareDateTime(self.value, date2)<=0);
end;

function TDateTimeObject.isBetween(date1, date2: TDateTimeObject): boolean;
begin
  Result:=self.isBetween(date1.value, date2.value);
end;

function TDateTimeObject.timeIsBetween(date1, date2: TTime): boolean;
begin
  Result:=(DateUtils.CompareTime(self.timeOf, date1)>=0) and (DateUtils.CompareTime(self.timeOf, date2)<=0);
end;

function TDateTimeObject.dateIsBetween(date1, date2: TDate): boolean;
begin
  Result:=(DateUtils.CompareDate(self.dateOf, date1)>=0) and (DateUtils.CompareTime(self.dateOf, date2)<=0);
end;

function TDateTimeObject.dateOf: TDate;
begin
  Result:=DateUtils.DateOf(self.value);
end;

function TDateTimeObject.timeOf: TTime;
begin
  Result:=DateUtils.TimeOf(self.value);
end;

function TDateTimeObject.dateIsBetween(date1, date2: TDateTimeObject): boolean;
begin
  Result:=self.dateIsBetween(date1.dateOf, date2.DayOf);
end;

function TDateTimeObject.timeIsBetween(date1, date2: TDateTimeObject): boolean;
begin
  Result:=self.timeIsBetween(date1.timeOf, date2.timeOf);
end;

function TDateTimeObject.diff(datetime: TDateTimeObject): TDateTimeObject;
begin
  Result:=TDateHelper.diff(self, datetime);
end;

procedure TDateTimeObject.refresh;
begin
  Self.value:=Now;
end;

procedure TDateTimeObject.assign(source: TDateTimeObject);
begin
  self.value:=source.value;
  self.format:=source.format;
  self.format2:=source.format2;
  self.timeZone:=source.timeZone;
end;

{ TDateHelper }

class function TDateHelper.convertFrom(chr: string): tpDateTime;
var return: tpDateTime;
begin
  return:=td_none;
  chr:=LowerCase(chr);
  if (chr='y') then begin
    return:=td_year;
  end;
  if (chr='m') then begin
    return:=td_month;
  end;
  if (chr='d') then begin
    return:=td_day;
  end;
  if (chr='h') then begin
    return:=td_hour;
  end;
  if (chr='n') then begin
    return:=td_minute;
  end;
  if (chr='s') then begin
    return:=td_second;
  end;
  if (chr='z') then begin
    return:=td_millisecond;
  end;
  if (chr='x') then begin
    return:=td_timezone;
  end;
  result:=return;
end;

class procedure TDateHelper.loadValues(var year, month, day, hour, minute, second:Word; var millisecond: LongWord; var timeZone: integer; lookup: tLookupDate);
var val: integer;
begin
  year:=0;
  month:=0;
  day:=0;
  hour:=0;
  minute:=0;
  second:=0;
  millisecond:=0;
  timeZone:=0;
  if TryStrToInt(trim(lookup[td_year]), val) then begin
    year:=val;
  end;
  if TryStrToInt(trim(lookup[td_month]), val) then begin
    month:=val;
  end;
  if TryStrToInt(trim(lookup[td_day]), val) then begin
    day:=val;
  end;
  if TryStrToInt(trim(lookup[td_hour]), val) then begin
    hour:=val;
  end;
  if TryStrToInt(trim(lookup[td_minute]), val) then begin
    minute:=val;
  end;
  if TryStrToInt(trim(lookup[td_second]), val) then begin
    second:=val;
  end;
  if TryStrToInt(trim(lookup[td_millisecond]), val) then begin
    millisecond:=val;
  end;
  if TryStrToInt(trim(lookup[td_timeZone]), val) then begin
    timeZone:=val;
  end;
end;

class procedure TDateHelper.loadLookupValues(year, month, day, hour, minute, second: word; millisecond: LongWord; timeZone: integer; var lookup: tLookupDateTime);
begin
  lookup[td_none]        :=0;
  lookup[td_year]        :=year;
  lookup[td_month]       :=month;
  lookup[td_day]         :=day;
  lookup[td_hour]        :=hour;
  lookup[td_minute]      :=minute;
  lookup[td_second]      :=second;
  lookup[td_millisecond] :=millisecond;
  lookup[td_timezone]    :=timeZone;
end;

class function TDateHelper.normalizeValue(formatedValue: string; lookupMask: tLookupDate; value: integer; type_date: tpDateTime): string;
var partOfMask, strvalue: string;
  len: integer;
begin
  partOfMask:=lookupMask[type_date];
  strvalue:=IntToStr(value);
  len:=length(partOfMask);
  if value<0 then begin
    strvalue:=IntToStr(value * -1);
    strvalue:=padLeft(strvalue, '0', len);
    strvalue[1]:='-';
  end else begin
    if type_date=td_timezone then begin
      len:=len-1;
    end;
    strvalue:=padLeft(strvalue, '0', len);
  end;
  Result:=StringReplace(formatedValue, partOfMask, strvalue, [rfReplaceAll]);
end;

class function TDateHelper.formatDateTime(format: string; date: TDateTime; timeZone: integer): string;
var i:integer;
  chr: char;
  dateTimeFormated, mask: string;
  index: tpDateTime;
  year, month, day, hour, minute, second, milisecond: word;
  lookupMask: tLookupDate;
  lookup:tLookupDateTime;
begin
  DecodeDateTime(date,  year, month, day, hour, minute, second, milisecond);
  TDateHelper.loadLookupValues(year, month, day, hour, minute, second, milisecond, timeZone, lookup);
  dateTimeFormated:='';
  mask:='';
  for i:=1 to length(format) do begin
    chr:=format[i];
    index:=self.convertFrom(chr);
    if index<>td_none then begin
      lookupMask[index]:=lookupMask[index] + chr;
    end;
  end;
  dateTimeFormated:=format;
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, year,       td_year);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, month,      td_month);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, day,        td_day);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, hour,       td_hour);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, minute,     td_minute);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, second,     td_second);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, milisecond, td_millisecond);
  dateTimeFormated:=self.normalizeValue(dateTimeFormated, lookupMask, timeZone,   td_timezone);
  result:=dateTimeFormated;
end;

class function TDateHelper.Match(lookup:tLookupDateTime; lookupMask: tLookupDate): tLookupDate;
var formated: tLookupDate;
  timeZone: string;
begin
  formated[td_none]:='';
  formated[td_year]:=        self.processValue(lookup, lookupMask, td_year);
  formated[td_month]:=       self.processValue(lookup, lookupMask, td_month);
  formated[td_day]:=         self.processValue(lookup, lookupMask, td_day);
  formated[td_hour]:=        self.processValue(lookup, lookupMask, td_hour);
  formated[td_minute]:=      self.processValue(lookup, lookupMask, td_minute);
  formated[td_second]:=      self.processValue(lookup, lookupMask, td_second);
  formated[td_millisecond]:= self.processValue(lookup, lookupMask, td_millisecond);
  timeZone:=                 self.processValue(lookup, lookupMask, td_timezone);
  if timeZone[1]<>'-' then begin
    timeZone[1]:=' ';
    timeZone:=trim(timeZone);
  end;
  formated[td_timeZone]:=timeZone;
  result:=formated;
end;

class function TDateHelper.processValue(lookup:tLookupDateTime; lookupMask: tLookupDate; tpDate: tpDateTime): string;
var len, i, index, offset: integer;
  valueStr, partOfMask: string;
  value:word;
begin
  value:=lookup[tpDate];
  partOfMask:=lookupMask[tpDate];
  valueStr:=IntToStr(value);
  valueStr:= padLeft(valueStr, '0', length(partOfMask));
  offset:=0;
  if partOfMask<>'' then begin
    offset:=length(partOfMask);
    if (value>9) and (length(partOfMask)<2) then begin
      offset:=offset+1;
    end;
  end;
  len:=length(valueStr);
  index:=len;
  for i:=offset downto 1 do begin
    result:=valueStr[index]+result;
    index:=index-1;
  end;
  if (partOfMask<>'') and (length(result)=1) and (length(partOfMask)>1) and (value<10) then begin
    result:='0'+result;
  end;
end;

class procedure TDateHelper.normalize(var year, month, day: word);
begin
  if year=0 then begin
    year:=1899;
  end;
  if month=0 then begin
    month:=12;
  end;
  if day=0 then begin
    day:=30;
  end;
end;

class function TDateHelper.decode(format: string; value: string): TDateTimeObject;
var i, len:integer;
  chr, chrValue: char;
  index: tpDateTime;
  year, month, day, hour, minute, second: word;
  milisecond: Longword;
  timeZone: integer;
  lookup: tLookupDate;
begin
  result:=TDateTimeObject.create(format, 0);
  value:=trim(value);
  len:=length(value);
  if len=Length(format) then begin
    for i:=1 to len do begin
      chr:=format[i];
      chrValue:=value[i];
      index:=TDateHelper.convertFrom(chr);
      if index<>td_none then begin
        lookup[index]:=lookup[index] + chrValue;
      end;
    end;
    try
      TDateHelper.loadValues(year, month, day, hour, minute, second, milisecond, timeZone, lookup);
      if milisecond>99999 then begin
        milisecond:=(milisecond div 10000);
      end else if milisecond>100 then begin
        milisecond:=(milisecond div 100);
      end;
      TDateHelper.normalize(year, month, day);
      result.value:=encodeDateTime(year, month,day, hour, minute, second, milisecond);
      Result.timeZone:=timeZone;
    except
      on e: Exception do begin
        raise;
      end;
    end;
  end else begin
    raise Exception.Create('O valor não condiz com o formato');
  end;
end;

class function TDateHelper.diff(value1, value2: TDateTimeObject): TDateTimeObject;
var date1, date2: TDateTime;
begin
  date1:=IncHour(value1.value, value1.timeZone);
  date2:=IncHour(value2.value, value2.timeZone);
  Result:=TDateTimeObject.create(value1.format, 0);
  Result.value:=date1-date2;
  Result.timeZone:=0;
end;

class procedure TDateHelper.inc(dateTimeObject: TDateTimeObject; incValue: integer; tp_DateTime: tpDateTime);
begin
  if tp_DateTime=td_year then begin
    dateTimeObject.value:=IncYear(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_month then begin
    dateTimeObject.value:=IncMonth(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_day then begin
    dateTimeObject.value:=IncDay(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_hour then begin
    dateTimeObject.value:=IncHour(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_minute then begin
    dateTimeObject.value:=IncMinute(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_second then begin
    dateTimeObject.value:=IncSecond(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_millisecond then begin
    dateTimeObject.value:=IncMilliSecond(dateTimeObject.value, incValue);
  end else if tp_DateTime=td_timezone then begin
    dateTimeObject.timeZone:=dateTimeObject.timeZone + incValue;
  end else begin
    raise exception.Create('Tipo do incremento para datetime é inválido [className: "TDateHelper", method: "inc"]');
  end;
end;

end.

