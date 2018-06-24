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
    else Error := '���� �������������� �������';
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
  else Error := '������� ������ ���������� �����������';
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
       ( ('arcsin', '�'), ('arccos', '�'), ('sin',    '�'),
         ('cos',    '�'), ('arcctg', '�'), ('arctg',  '�'),
         ('ctg',    '�'), ('tg',     '�'), ('ln',     '�'),
         ('arsh',   '�'), ('arch',   '�'), ('arth',   '�'),
         ('arcth',  '�'), ('sh',     '�'), ('ch',     '�'),
         ('cth',    '�'), ('th',     '�'), ('abs',    '�'),
         ('exp',    '�'), ('lg',     '�'), ('round',  '�'),
         ('trunc',  '�'), ('frac',   '�'), ('log2',   '�'),
         ('sqrt',   '�'), ('sqr',    '�'), ('sign',   '�') );

  type TTRArr = array[ 0..7, 1..10 ] of byte;

  {********* ������� ������� : *********}

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

  // �������� ������� ��������� �������� ��������
  for i := 1 to TableSize do
    begin
      while Pos( Table[ i, 1 ], tmpParseExpression ) > 0 do
        begin
          Position := Pos( Table[ i, 1 ], tmpParseExpression );
          Delete( tmpParseExpression, Position,  Length( Table[ i, 1 ] ) );
          Insert( Table[ i, 2 ], tmpParseExpression, Position )
        end
    end;

  // �������� ����� �� ��� ���������
  while Pos( 'Pi', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( 'Pi', tmpParseExpression );
      Delete( tmpParseExpression, Position,  Length( 'Pi' ) );
      Insert( FloatToStr( Pi ), tmpParseExpression, Position )
    end;

  // �������� ����� X ��� ���������
  while Pos( 'X', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( 'X', tmpParseExpression );
      Delete( tmpParseExpression, Position,  1 );
      Insert( FloatToStr( X ), tmpParseExpression, Position )
    end;

  // �������� ������ "," �� ������ "."
  while Pos( ',', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( ',', tmpParseExpression );
      Delete( tmpParseExpression, Position,  1 );
      Insert( '.', tmpParseExpression, Position )
    end;

  // ����������� �� �������� ������
  if tmpParseExpression[ 1 ] = '-'
  then tmpParseExpression := '0' + tmpParseExpression;

  while Pos( '(-', tmpParseExpression ) <> 0 do
    begin
      Position := Pos( '(-', tmpParseExpression );
      Insert( '0', tmpParseExpression, Position + 1 )
    end;

  // �������� ��������� ���������� ��������� ���������� ��������
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
                  Error := '������ �� ��������� ���������: ��������� ��������� "' + ConstantsList.StringItems[ ConstantsList.ItemsCount - 1 ] + '" �� �������� ������. ������� ��������� ��������� �������';
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
            1 : // 1 - ��������� ������ �� ������� ������ � ����;
                  Push;
            2 : // 2 - ������� ������ �� ����� � ��������� ��� � �������� ������;
                  ResultExpression := ResultExpression + Pop;
            3 : // 3 - ������� ������ ")" �� ������� ������ � ������ "(" �� �����;
                begin
                  Delete( tmpParseExpression, 1, 1 );
                  Dec( ParserStek.ItemsCount );
                end;
            4 : // 4 - �������� ��������� ��������������;
                  BREAK;
            5 : // 5 - ������ ��������� ���������;
                  Error := '������ ��������� ��������� ���������';
            6 : // 6 -  ��������� ������ �� ������� ������ - � ��������;
                begin
                  ResultExpression := ResultExpression + tmpParseExpression[ 1 ];
                  Delete( tmpParseExpression, 1, 1 );
                end;
            7 : // 7 - ������: ����� ������� ����������� "(";
                  Error := '������: ����� ������� ����������� "("';
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
         '�'..'�', '�'..'�' : {��������� ������ - �������}
               Result := 9;
         'A'..'Z' : {��������� ������ - ����������}
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
         else  Result := 7 {- ������ ������� (���������� � ���� �� ��������)}
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
                {�������� ��������}
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
                {���������}
                'A'..'Z'  : begin
                              Push( PostfixParser.ConstantsList.FloatItems[ Ord( PostfixExpression[ i ] ) - Ord( 'A' ) ] );
                            end;
                {������� �������� (�������)}
                '�'..'�',
                '�'..'�'  : begin
                              Operand1 := Pop;
                              OpResult := 0;
                              case PostfixExpression[ i ] of
                                 '�' : OpResult := arcsin( Operand1 );
                                 '�' : OpResult := arccos( Operand1 );
                                 '�' : OpResult := sin( Operand1 );
                                 '�' : OpResult := cos( Operand1 );
                                 '�' : if arctan( Operand1 ) <> 0
                                       then OpResult := 1 / arctan( Operand1 )
                                       else OpResult := 1.5 * exp( 308 * ln( 10 ) );
                                 '�' : OpResult := arctan( Operand1 );
                                 '�' : if tan( Operand1 ) <> 0
                                       then OpResult := 1 / tan( Operand1 )
                                       else OpResult := 1.5 * exp( 308 * ln( 10 ) );
                                 '�' : OpResult := tan( Operand1 );
                                 '�' : OpResult := ln( Operand1 );
                                 '�' : OpResult := arcsinh( Operand1 );
                                 '�' : OpResult := arccosh( Operand1 );
                                 '�' : OpResult := arctanh( Operand1 );
                                 '�' : OpResult := arccoth( Operand1 );
                                 '�' : OpResult := sinh( Operand1 );
                                 '�' : OpResult := cosh( Operand1 );
                                 '�' : OpResult := coth( Operand1 );
                                 '�' : OpResult := tanh( Operand1 );
                                 '�' : OpResult := abs( Operand1 );
                                 '�' : OpResult := exp( Operand1 );
                                 '�' : OpResult := log10( Operand1 );
                                 '�' : OpResult := round( Operand1 );
                                 '�' : OpResult := trunc( Operand1 );
                                 '�' : OpResult := frac( Operand1 );
                                 '�' : OpResult := log2( Operand1 );
                                 '�' : if Operand1 >= 0
                                       then OpResult := sqrt( Operand1 )
                                       else Error := '������� ���������� ����������� ����� �� �������������� �����';
                                 '�' : OpResult := sqr( Operand1 );
                                 '�' : if Operand1 < 0
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
