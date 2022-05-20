unit StringFunctions;

interface

uses classes, windows, sysutils;

function padLeft(const str: string; chr: char;size: Integer): string;
function padRight(const str: String; chr: char;size: Integer): string;

implementation

function padLeft(const str: string; chr: char;size: Integer): string;
{$IFDEF VER150}
var len, position: integer;
{$ENDIF}
begin
  {$IFNDEF VER150}
  Result:=str.PadLeft(size, chr);
  {$ELSE IF}
  len:=length(str);
  if len<size then begin
    SetLength(Result, size);
    FillChar(Result[1], size, byte(chr));
    if len>0 then begin
      position:=size-len+1;
      if (position>0) then begin
        MoveMemory(@Result[position], @Str[1], len);
      end else begin
        Result:=str;
      end;
    end;
  end else begin
    Result:=str;
  end;
  {$ENDIF}
end;

function padRight(const str: String; chr: char;size: Integer): string;
{$IFDEF VER150}
var len: integer;
{$ENDIF}
begin
  {$IFNDEF VER150}
  Result:=str.padRight(size, chr);
  {$ELSE IF}
  len:=length(str);
  if len<size then begin
    SetLength(Result, size);
    FillChar(Result[1], size, byte(chr));
    if len>0 then begin
      MoveMemory(@Result[1], @Str[1], len);
    end;
  end else begin
    Result:=str;
  end;
  {$ENDIF}
end;

end.
