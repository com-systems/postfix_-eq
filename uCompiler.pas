unit uCompiler;

// log := ShortString(trim(s))

{********************************}  interface {********************************}

uses SysUtils, Math;

  type
       TConstantsList = record
                          CharItems    : array of Char;
                          StringItems  : array of string;
                          FloatItems   : array of double;
                          ItemsCount   : integer;
                        end;

       TParserStek = record
                       Items : array of string;
                       ItemsCount : integer;
                     end;

       TPostfixParser = class
                          ConstantsList : TConstantsList;
                          Error         : string;

                          private
                            ParserStek        : TParserStek;
                            FParseExpression  : string;
                            FResultExpression : string;
                            FX                : double;

                            function Push : boolean;
                            function Pop  : char;
                            function SymbNumInStek   : byte;
                            function SymbNumInputStr : byte;

                          public
                            property ParseExpression  : string read FParseExpression  write FParseExpression;
                            property ResultExpression : string read FResultExpression write FResultExpression;
                            property X                : double read FX                write FX;

                            procedure StartParsing;
                        end;

       TPostfixCalculatorStek = record
                                  Items : array of double;
                                  ItemsCount : integer;
                                end;

       TPostfixParserCalculator = class
                                    Error         : string;

                                    private
                                      PostfixCalculatorStek : TPostfixCalculatorStek;

                                      FExpression           : string;
                                      FResultValue          : double;
                                      FX                    : double;

                                      function Push( Value : double ) : boolean;
                                      function Pop  : double;

                                    public
                                      PostfixExpression     : string;
                                      
                                      property Expression  : string read FExpression  write FExpression;
                                      property ResultValue : double read FResultValue write FResultValue;
                                      property X           : double read FX           write FX;

                                      procedure Calculate;
                                  end;


   var tmpParseExpression : string;


{*****************************}  implementation {******************************}

{ TPostfixParser }

{------------------------------------------------------------------------------}
function TPostfixParser.Pop: char;
begin
  Result := #0;
  with ParserStek do
    if ItemsCount > 0
    then begin
           Result := Items[ ItemsCount - 1 ][ 1 ];
           Dec( ItemsCount );
//           SetLength( Items, ItemsCount )
         end
    else Error := 'Стек преждевременно опустел';
end;
{------------------------------------------------------------------------------}
function TPostfixParser.Push: boolean;
begin
  Result := FALSE;
  if tmpParseExpression <> ''
  then begin
         with ParserStek do
           begin
             Inc( ItemsCount );
             SetLength( Items, ItemsCount );
             Items[ ItemsCount - 1 ] := tmpParseExpression[ 1 ];
             Delete( tmpParseExpression, 1, 1 )
           end;
         Result := TRUE
       end
  else Error := 'Входная строка неожиданно закончилась';
end;
{------------------------------------------------------------------------------}
procedure TPostfixParser.StartParsing;
  //type string6 = string[ 6 ];
  var i, Position : byte;
      FoundDigit : boolean;
      StrValue : string;
      ValCode : integer;

  const
    TableSize = 27;
    Table : array[ 1..TableSize, 1..2 ] of string =
       ( ('arcsin', 'а'), ('arccos', 'б'), ('sin',    'в'),
         ('cos',    'г'), ('arcctg', 'д'), ('arctg',  'е'),
         ('ctg',    'ж'), ('tg',     'з'), ('ln',     'и'),
         ('arsh',   'к'), ('arch',   'л'), ('arth',   'м'),
         ('arcth',  'н'), ('sh',     'о'), ('ch',     'п'),
         ('cth',    'р'), ('th',     'с'), ('abs',    'т'),
         ('exp',    'у'), ('lg',     'ф'), ('round',  'х'),
         ('trunc',  'ц'), ('frac',   'ч'), ('log2',   'ш'),
         ('sqrt',   'ъ'), ('sqr',    'ы'), ('sign',   'ь') );

  type TTRArr = array[ 0..7, 1..10 ] of byte;

  {********* ТАБЛИЦА РЕШЕНИЙ : *********}

  const TR : TTRArr =  ( ( 4, 1, 1, 1, 1, 1, 1, 5, 1, 6 ),
                         ( 2, 2, 2, 1, 1, 1, 1, 2, 1, 6 ),
                         ( 2, 2, 2, 1, 1, 1, 1, 2, 1, 6 ),
                         ( 2, 2, 2, 2, 2, 1, 1, 2, 1, 6 ),
                         ( 2, 2, 2, 2, 2, 1, 1, 2, 1, 6 ),
                         ( 2, 2, 2, 2, 2, 2, 1, 2, 1, 6 ),
                         ( 5, 1, 1, 1, 1, 1, 1, 3, 1, 6 ),
                         ( 2, 2, 2, 2, 2, 2, 1, 7, 7, 6 ));
begin
  Error := '';
  ResultExpression := '';

  tmpParseExpression := ParseExpression;

  // Заменяем функции символами русского алфавита
  for i := 1 to TableSize do
    begin
      while Pos( Table[ i, 1 ], tmpParseExpression ) > 0 do
        begin
          Position := Pos( Table[ i, 1 ], tmpParseExpression );
          Delete( tmpParseExpression, Position,  Length( Table[ i, 1 ] ) );
          Insert( Table[ i, 2 ], tmpParseExpression, Position )
        end
    end;

  // Заменяем число Пи его значением
  while Pos( 'Pi', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( 'Pi', tmpParseExpression );
      Delete( tmpParseExpression, Position,  Length( 'Pi' ) );
      Insert( FloatToStr( Pi ), tmpParseExpression, Position )
    end;

  // Заменяем число X его значением
  while Pos( 'X', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( 'X', tmpParseExpression );
      Delete( tmpParseExpression, Position,  1 );
      Insert( FloatToStr( X ), tmpParseExpression, Position )
    end;

  // Заменяем символ "," на символ "."
  while Pos( ',', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( ',', tmpParseExpression );
      Delete( tmpParseExpression, Position,  1 );
      Insert( '.', tmpParseExpression, Position )
    end;

  // Избавляемся от унарного минуса
  if tmpParseExpression[ 1 ] = '-'
  then tmpParseExpression := '0' + tmpParseExpression;

  while Pos( '(-', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( '(-', tmpParseExpression );
      Insert( '0', tmpParseExpression, Position + 1 )
    end;

  // Заменяем константы прописными символами латинского алфавита
  ConstantsList.ItemsCount := 0;
  repeat
    FoundDigit := FALSE;
    Position := 0;
    for i := 1 to Length( tmpParseExpression ) do
      if tmpParseExpression[ i ] in [ '0'..'9' ]
      then begin
             FoundDigit := TRUE;
             Position := i;
             BREAK
           end;
    if FoundDigit
    then begin
           StrValue := '';
           for i := Position to Length( tmpParseExpression ) do
             if tmpParseExpression[ i ] in [ '0'..'9', '.', ',' ]
             then StrValue := StrValue + tmpParseExpression[ i ]
             else BREAK;
           Inc( ConstantsList.ItemsCount );
           SetLength( ConstantsList.StringItems, ConstantsList.ItemsCount );
           SetLength( ConstantsList.CharItems,   ConstantsList.ItemsCount );
           SetLength( ConstantsList.FloatItems,  ConstantsList.ItemsCount );
           ConstantsList.StringItems[ ConstantsList.ItemsCount - 1 ] := StrValue;

           Val( ConstantsList.StringItems[ ConstantsList.ItemsCount - 1 ], ConstantsList.FloatItems[ ConstantsList.ItemsCount - 1 ], ValCode );
           if ValCode <> 0
           then begin
                  Error := 'Ошибка во введенном выражении: введенная подстрока "' + ConstantsList.StringItems[ ConstantsList.ItemsCount - 1 ] + '" не является числом. Процесс обработки выражения прерван';
                  EXIT
                end;

           if Error = ''
           then begin
                  ConstantsList.CharItems[ ConstantsList.ItemsCount - 1 ] := Chr( Ord( 'A' ) + ConstantsList.ItemsCount - 1 );
                  Delete( tmpParseExpression, Position, Length( ConstantsList.StringItems[ ConstantsList.ItemsCount - 1 ] ) );
                  Insert( ConstantsList.CharItems[ ConstantsList.ItemsCount - 1 ], tmpParseExpression, Position )
                end;
         end;
  until not FoundDigit;

  ParserStek.ItemsCount := 0;
  SetLength( ParserStek.Items, ParserStek.ItemsCount );
  if Error = ''
  then Repeat
          case TR[ SymbNumInStek, SymbNumInputStr ] of
            1 : // 1 - поместить символ из входной строки в стек;
                  Push;
            2 : // 2 - извлечь символ из стека и отправить его в выходную строку;
                  ResultExpression := ResultExpression + Pop;
            3 : // 3 - удалить символ ")" из входной строки и символ "(" из стека;
                begin
                  Delete( tmpParseExpression, 1, 1 );
                  Dec( ParserStek.ItemsCount );
                end;
            4 : // 4 - успешное окончание преобразования;
                  BREAK;
            5 : // 5 - ошибка скобочной структуры;
                  Error := 'Ошибка скобочной структуры выражения';
            6 : // 6 -  переслать символ из входной строки - в выходную;
                begin
                  ResultExpression := ResultExpression + tmpParseExpression[ 1 ];
                  Delete( tmpParseExpression, 1, 1 );
                end;
            7 : // 7 - ошибка: после функции отсутствует "(";
                  Error := 'Ошибка: после функции отсутствует "("';
          end;
          if Error <> ''
          then BREAK;
       Until FALSE;
end;
{------------------------------------------------------------------------------}
function TPostfixParser.SymbNumInputStr: byte;
begin
  Result := 1;
  if tmpParseExpression = ''
  then Result := 1
  else case tmpParseExpression[ 1 ] of
         '+' : Result := 2;
         '-' : Result := 3;
         '*' : Result := 4;
         '/' : Result := 5;
         '^' : Result := 6;
         '(' : Result := 7;
         ')' : Result := 8;
         'а'..'п', 'р'..'я' : {очередной символ - функция}
               Result := 9;
         'A'..'Z' : {очередной символ - переменная}
               Result :=10;
       end;{case}
end;
{------------------------------------------------------------------------------}
function TPostfixParser.SymbNumInStek: byte;
begin
//  Result := 0;
  if ParserStek.ItemsCount = 0
  then Result := 0
  else case ParserStek.Items[ ParserStek.ItemsCount - 1 ][ 1 ] of
         '+' : Result := 1;
         '-' : Result := 2;
         '*' : Result := 3;
         '/' : Result := 4;
         '^' : Result := 5;
         '(' : Result := 6;
         else  Result := 7 {- символ функции (переменные в стек не попадают)}
       end{case}
end;
{------------------------------------------------------------------------------}

{ TPostfixParserCalculator }

{------------------------------------------------------------------------------}
procedure TPostfixParserCalculator.Calculate;
  var i : integer;
      Operand1, Operand2, OpResult : double;
      PostfixParser : TPostfixParser;
begin
  PostfixParser := TPostfixParser.Create;
  PostfixParser.ParseExpression := Expression;
  PostfixParser.X := X;
  PostfixParser.StartParsing;

  if PostfixParser.Error <> ''
  then Error := PostfixParser.Error
  else begin
         PostfixExpression := PostfixParser.ResultExpression;

         PostfixCalculatorStek.ItemsCount := 0;
         SetLength( PostfixCalculatorStek.Items, PostfixCalculatorStek.ItemsCount );

         for i := 1 to Length( PostfixExpression ) do
            begin
              case PostfixExpression[ i ] of
                {бинарные операции}
                '+' : begin
                        Operand2 := Pop;
                        Operand1 := Pop;
                        OpResult := Operand1 + Operand2;
                        Push( OpResult )
                      end;
                '-' : begin
                        Operand2 := Pop;
                        Operand1 := Pop;
                        OpResult := Operand1 - Operand2;
                        Push( OpResult )
                      end;
                '*' : begin
                        Operand2 := Pop;
                        Operand1 := Pop;
                        OpResult := Operand1 * Operand2;
                        Push( OpResult )
                      end;
                '/' : begin
                        Operand2 := Pop;
                        Operand1 := Pop;
                        if Operand2 <> 0
                        then OpResult := Operand1 / Operand2
                        else OpResult := 1.5 * exp( 308 * ln( 10 ) );
                        Push( OpResult )
                      end;
                '^' : begin
                        Operand2 := Pop;
                        Operand1 := Pop;
                        // a^b = exp( b * ln(a) )
                        OpResult := exp( Operand2 * ln( Operand1 ) );
                        Push( OpResult )
                      end;
                {константы}
                'A'..'Z'  : begin
                              Push( PostfixParser.ConstantsList.FloatItems[ Ord( PostfixExpression[ i ] ) - Ord( 'A' ) ] );
                            end;
                {унарные операции (функции)}
                'а'..'п',
                'р'..'я'  : begin
                              Operand1 := Pop;
                              OpResult := 0;
                              case PostfixExpression[ i ] of
                                 'а' : OpResult := arcsin( Operand1 );
                                 'б' : OpResult := arccos( Operand1 );
                                 'в' : OpResult := sin( Operand1 );
                                 'г' : OpResult := cos( Operand1 );
                                 'д' : if arctan( Operand1 ) <> 0
                                       then OpResult := 1 / arctan( Operand1 )
                                       else OpResult := 1.5 * exp( 308 * ln( 10 ) );
                                 'е' : OpResult := arctan( Operand1 );
                                 'ж' : if tan( Operand1 ) <> 0
                                       then OpResult := 1 / tan( Operand1 )
                                       else OpResult := 1.5 * exp( 308 * ln( 10 ) );
                                 'з' : OpResult := tan( Operand1 );
                                 'и' : OpResult := ln( Operand1 );
                                 'к' : OpResult := arcsinh( Operand1 );
                                 'л' : OpResult := arccosh( Operand1 );
                                 'м' : OpResult := arctanh( Operand1 );
                                 'н' : OpResult := arccoth( Operand1 );
                                 'о' : OpResult := sinh( Operand1 );
                                 'п' : OpResult := cosh( Operand1 );
                                 'р' : OpResult := coth( Operand1 );
                                 'с' : OpResult := tanh( Operand1 );
                                 'т' : OpResult := abs( Operand1 );
                                 'у' : OpResult := exp( Operand1 );
                                 'ф' : OpResult := log10( Operand1 );
                                 'х' : OpResult := round( Operand1 );
                                 'ц' : OpResult := trunc( Operand1 );
                                 'ч' : OpResult := frac( Operand1 );
                                 'ш' : OpResult := log2( Operand1 );
                                 'ъ' : if Operand1 >= 0
                                       then OpResult := sqrt( Operand1 )
                                       else Error := 'Попытка извлечения квадратного корня из отрицательного числа';
                                 'ы' : OpResult := sqr( Operand1 );
                                 'ь' : if Operand1 < 0
                                       then OpResult := -1
                                       else OpResult := 1;
                              end;
                              Push( OpResult )
                            end;
              end;{case}
              if Error <> ''
              then break;
            end;
          ResultValue := Pop;
       end;
  PostfixParser.Destroy;
end;
{------------------------------------------------------------------------------}
function TPostfixParserCalculator.Pop: double;
begin
  Result := PostfixCalculatorStek.Items[ PostfixCalculatorStek.ItemsCount - 1 ];
  Dec( PostfixCalculatorStek.ItemsCount )
end;
{------------------------------------------------------------------------------}
function TPostfixParserCalculator.Push( Value : double ): boolean;
begin
  Inc( PostfixCalculatorStek.ItemsCount );
  SetLength( PostfixCalculatorStek.Items, PostfixCalculatorStek.ItemsCount );
  PostfixCalculatorStek.Items[ PostfixCalculatorStek.ItemsCount - 1 ] := Value;
  result := TRUE
end;
{------------------------------------------------------------------------------}


end.
