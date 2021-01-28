program nonogram;
uses math, sysutils;

type 
    Cell       = (Fill, Empty, Unknown);
    Board      = Array of Array of Cell;
    Clues      = Array of Integer;
    TClueArray = Array of Clues;

function convertClue(strarr : Array of AnsiString) : TClueArray;
var
    res  : TClueArray;
    temp : Array of AnsiString;
    i, j : Longint;
begin
    setLength(res, Length(strarr));
    for i := 0 to Length(strarr)-1 do begin
        temp := strarr[i].Split(' ');
        setLength(res[i], Length(temp));
        for j := 0 to Length(temp)-1 do res[i][j] := StrToInt(temp[j]);
    end;
    Exit(res);
end;

function initBoard(height, width : Integer) : Board;
var i, j : Longint; b : Board;
begin
    setLength(b, height);
    for i := 0 to height-1 do begin
        setLength(b[i], width);
        for j := 0 to width-1 do b[i][j] := Unknown;
    end;
    Exit(b);
end;

procedure showBoard(b : Board);
var i, j : Longint;
begin
    for i := 0 to Length(b)-1 do begin for j := 0 to Length(b[i])-1 do
        Case b[i][j] of 
            Fill    : write('O');
            Empty   : write(' ');
            Unknown : write('.');
        end; 
        writeln();
    end;
end;

function countFilled(arr : Array of Cell) : Clues;
var
    counting : Boolean = False;
    i, count : Integer;
    res      : Clues;
begin
    setLength(res, 0);
    count := 0;
    for i := 0 to Length(arr)-1 do begin
        if arr[i] = Unknown then break;
        if counting then
            if arr[i] = Fill then count += 1
            else begin 
                setLength(res, Length(res)+1);
                res[Length(res)-1] := count;
                counting := False;
                count    := 0;
            end
        else if arr[i] = Fill then begin
            counting := True;
            count := 1;
        end;
    end;
    if counting then begin
        setLength(res, Length(res)+1);
        res[Length(res)-1] := count;
    end;
    if Length(res) = 0 then res := [0];
    Exit(res);
end;

function countFilledHard(arr : Array of Cell) : Clues;
var
    counting : Boolean = False;
    i, count : Integer;
    res      : Clues;
begin
    setLength(res, 0);
    count := 0;
    for i := 0 to Length(arr)-1 do begin
        if arr[i] = Unknown then break;
        if counting then
            if arr[i] = Fill then count += 1
            else begin 
                setLength(res, Length(res)+1);
                res[Length(res)-1] := count;
                counting := False;
                count    := 0;
            end
        else if arr[i] = Fill then begin
            counting := True;
            count := 1;
        end;
    end;
    if counting and (arr[i] <> Unknown) then begin
        setLength(res, Length(res)+1);
        res[Length(res)-1] := count;
    end;
    Exit(res);
end;

function isFull(arr : Array of Cell) : Boolean;
begin Exit(arr[Length(arr)-1] <> Unknown) end;

function isValidClue(arr, clue : Clues; isfull, hard : Boolean) : Boolean;
var i : Integer;
begin
    if isfull or hard then begin
        if isfull then if Length(arr) <> Length(clue) then Exit(false);
        for i := 0 to min( Length(clue), Length(arr) )-1 do
            if arr[i] <> clue[i] then Exit(false);
    end
    else begin
        if Length(arr) > Length(clue) then Exit(false);
        for i := 0 to min( Length(clue), Length(arr) )-1 do
            if arr[i] > clue[i] then Exit(false);
    end;
    Exit(True);
end;

function isValid(b : Board; tc, lc : TClueArray; row,col : Integer) : Boolean;
var 
    i       : Integer;
    tempcol : Array of Cell;
begin
    { Check Rows }
    if not isValidClue(countFilled(b[row]), lc[row], isFull(b[row]), false) then Exit(False);
    if b[row][col] = Empty then 
        if not isValidClue(countFilledHard(b[row]), lc[row], false, true) then Exit(False);
    { Check Columns }
    setLength(tempcol, Length(b));
    for i := 0 to Length(b)-1 do tempcol[i] := b[i][col];
    if not isValidClue(countFilled(tempcol), tc[col], isFull(tempcol), false) then Exit(False);
    if b[row][col] = Empty then 
        if not isValidClue(countFilledHard(tempcol), tc[col], false, true) then Exit(False);
    Exit(True);
end;

var
    done           : Boolean = False;
    textfile       : Text;
    tc_str, lc_str : AnsiString;
    tc_strarr, 
    lc_strarr      : Array of AnsiString;
    top_clue,
    left_clue      : TClueArray;
    i,
    width, height  : Integer;
    gameboard      : Board;
    printid        : Integer = 0;

procedure solve(b : Board; tc, lc : TClueArray; y, x : Integer);
var
    height, width,
    ny, nx : Integer;
    Tcell        : Cell;
    newb         : Board;
    filled       : Boolean;
begin
    if done then Exit;
    height := Length(b);
    width  := Length(b[0]);
    if b[height-1][width-1] <> Unknown then begin 
        done := true;
        showBoard(b);
    end;
    filled := b[y][width-1] <> Unknown;
    if filled then begin 
        if printid mod 100 = 0 then begin showBoard(b); writeln; end;
        printid += 1;
    end;
    nx := x + 1;
    ny := y;
    if nx >= width then begin
        ny += 1; if ny >= height then Exit;
        nx := nx mod width;
    end;

    if Random() < 0.5 then begin
        for Tcell := Fill to Empty do begin
            b[ny][nx] := Tcell;
            if isValid(b, tc, lc, ny, nx) then begin
                setLength(newb, height);
                for i := 0 to height-1 do newb[i] := Copy(b[i]);
                solve(newb, tc, lc, ny, nx);
            end;
        end;
    end else begin
        for Tcell := Empty downto Fill do begin
            b[ny][nx] := Tcell;
            if isValid(b, tc, lc, ny, nx) then begin
                setLength(newb, height);
                for i := 0 to height-1 do newb[i] := Copy(b[i]);
                solve(newb, tc, lc, ny, nx);
            end;
        end;
    end;

end;

begin
    assign(textfile, 'nonogram.txt');
    reset(textfile);
    readln(textfile, tc_str);
    readln(textfile, lc_str);
    close(textfile);

    randomize();
    tc_strarr := tc_str.Split(',');
    lc_strarr := lc_str.Split(',');
    width     := Length(tc_strarr);
    height    := Length(lc_strarr);

    gameboard := initBoard(height, width);

    top_clue  := convertClue(tc_strarr);
    left_clue := convertClue(lc_strarr);
    solve(gameboard, top_clue, left_clue, 0, -1);
end.
