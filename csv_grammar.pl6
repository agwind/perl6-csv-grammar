#!/usr/bin/env perl6

#use Grammar::Debugger;

use v6;

grammar CSV::Grammar {
   token TOP {
      <record>* % (\n|\r\n)
   }
   token record {
      <field>* % ','
   }
   token field {
      <quoted> | <non_quoted> | <empty>
   }
   token quoted {
      \" (<non_quoted>|<comma>|<newline>) * \"
   }
   token non_quoted {
      ( $<chars>=[ <-[ " , \n ]>+ ] | <double_dquote> ) ** 1..*
   }
   token double_dquote {
      \" ** 2
   }
   token comma {
      ','
   }
   token empty {
      ''
   }
   token newline {
      \n
   }
}

class CSV::Record {
   has @.fields;
}

class CSV {
   has CSV::Record @.records;

   method add ( CSV::Record $record is required){
      @.records.push($record);
   }
}

class CSV::Action {

   has CSV $.file = CSV.new();

   method TOP($/) {
      #say $/<record>.[0].perl;
      for $/<record> -> $record {
         #say "  Record: {$record.perl}";
         self.file.add($record.made);
      }
      # $/<record>.map: {
      #    say "  Record: ", $_.perl;
      #    $.file.add($_.made)
      # }
   }
   method record($/) {
      #say "Record: {$/.perl}";
      my @fields = $/<field>.map: {
         #say $_.perl;
         #say "Field: ",$_.made;
         $_.made;
      }
      #@fields.unshift($<field>.made);

      #say @fields.perl;
      my $csv = CSV::Record.new( fields => @fields );
      $/.make: $csv;
      #say $csv.perl;
   }
   method field($/) {
      my $value = $<quoted>.defined ?? $<quoted>.made !!
         $<non_quoted>.defined ?? $<non_quoted>.made !!
            $<empty>.made;
      #say "Value: $value";
      $/.make: $value;
   }
   method quoted($/) {
      $/.make: join '', $/[0].map: {
         $_<non_quoted>.defined ?? $_<non_quoted>.made !!
            $_<comma>.defined ?? $_<comma>.made !!
               $_<newline>.made

      }
   }
   method non_quoted($/) {
      my $chars = join '', $/[0].map: {
         $_<chars>.defined ?? ~$_<chars> !! $_<double_dquote>.made
      }
      #say $chars;
      $/.make: $chars;
      #say $/.made
   }
   method double_dquote($/) {
      $/.make: '"';
   }
   method comma($/) {
      $/.make: ','
   }
   method empty($/) {
      $/.make: ''
   }
   method newline($/) {
      $/.make: "\n"
   }
}

my @DATA = (
    'a,b,c',
    'This is a test, Only a test, part 2',
    '"Impossible Dreams","Impossible Sunsets",Pair trees',
    '"Impossible Dreams","Impossible ""Sunsets""",Pair "" trees',
    ',,,',
    'a,b,c
    d,e,f
    g,h,i',
   'a,b,"c
   d",e,f',
);

for @DATA -> $line {

   say "Line: $line";
   my $action = CSV::Action.new();

   my $match_obj = CSV::Grammar.parse($line, :actions($action));
   #say "\nReturned: ",$match_obj.perl;
   my $csv = $action.file;

   #say $csv.perl;

   for $csv.records -> $record {
      say "  Record: {$record.gist}";
      for $record.fields -> $field {
         say "    Field: $field";
      }
   }

}
