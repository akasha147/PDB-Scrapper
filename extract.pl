#!/usr/bin/perl

use CGI;
use DBI;
use warnings;
use LWP::Simple;
use IO::String;

my $filename = "/home/guest/Documents/PDB_/";

open ($fh,"/home/akash/PDB_list.txt");


$dbh=DBI->connect('DBI:mysql:DCCPS', 'root', 'Nittcse16');
$k=0;
	
while (<$fh>)#Iterate for each PDB file
{
	chomp $_;
	my $data=uc($_);
	print $data."\n";
	if($data eq "")
	{
		next;
	}
	my $handle= IO::String->new(get("https://files.rcsb.org/view/".$data.".pdb"));#Webcrawling in the corresponding PDB File
	my $chain=0;
	my %list=(
          		"Protein" => [],
	   		"DNA"    => [],
	   		"RNA"    => [],
	 	 );

	my $dna=0;
	my $rna=0;
	my $protein=0;
	my $a="";
	my $type="NA";
	my $expt="NA";
	my $res=0;
	my $rval1=0;
	my $rval2=0;
	while (defined (my $line = <$handle>)) 
	{
		if($line=~ /^ATOM/&&substr($line,21,1) ne $a)#Find out the type of the chain
		{
			$a=substr($line,21,1);#Chain Identifier
			$sub=substr($line,17,3);#Residue Identifier
			$sub=~s/\s//g;

			if(length($sub)==3)#If Residuelength=3,then the chain is a protein chain
			{
				$list{"Protein"}[$protein++]=$a;

			} 
			elsif(length($sub)==2)#If Residuelength=3,then the chain is a DNA chain
			{
				$list{"DNA"}[$dna++]=$a;

			}
			else#Otherwise,the chain is a RNA Chain
			{
				$list{"RNA"}[$rna++]=$a;
			}
		}
		if($line=~ /^HEADER/)#Find out protein Type
		{
			$type=substr($line,10,39);
			$type=~s/^\s+|\s+$//g;
		}
		if($line=~ /^EXPDTA/)#Experiment Type
		{
			$expt=substr($line,10,40);
			chomp $expt;
			$expt=~s/^\s+|\s+$//g;
		}
		#REMARK   2 RESOLUTION.    1.80 ANGSTROMS.    
		if($line=~ /REMARK\s+2\s+RESOLUTION.\s+(\d+\.\d+)\s/)
		{
			$res=$1;
		}
		#REMARK   3   R VALUE            (WORKING SET)  : 0.210  
		if($line=~ /REMARK\s+3\s+R\s+VALUE\s+\(WORKING\s+SET\)\s+:\s+(\d+\.\d+)/ )
		{
			$rval1=$1*100;

		}  
		#REMARK   3   FREE R VALUE                      : 0.271 
		if($line=~ /REMARK\s+3\s+FREE\s+R\s+VALUE\s+:\s+(\d+\.\d+)/ )
		{
			$rval2=$1*100;
		}
	} 

	my $handle1=IO::String->new(get("http://www.rcsb.org/pdb/download/viewFastaFiles.do?structureIdList=".$data."&compressionType=uncompressed"));
	#Reterive Sequence from the corresponding FASTA files

	$init=0;
	%sequence=();
	$seq="";
	$wait=" ";
	$f=0;
	
	while (defined (my $line1 = <$handle1>)) 
	{
		if($line1 =~ /^>/&&$init==0)
		{
			$f=0;
			$a=substr($line1,6,1);
			if( grep( /$a/, @{$list{"Protein"}} ))
			{
				$wait="Protein";
				$f++;
			}

			elsif( grep( /$a/, @{$list{"DNA"}} ))
			{
				$wait="DNA";
				$f++;
			}
			elsif(grep( /$a/, @{$list{"RNA"}}))
			{
				$wait="RNA";
				$f++;
			}
			else
			{	
				next;
			}
			$init++;
		}
		
		elsif($line1 =~ /^>/&&$init)
		{
			if($f!=0)
			{
				if(!(exists $sequence{$seq})) 
				{
					push(@{$sequence{$seq}},$wait);
					push(@{$sequence{$seq}},$a);
				}
				else
				{
					push(@{$sequence{$seq}},$a);
				}	
			}
			$f=0;
			$a=substr($line1,6,1);
			if( grep( /$a/, @{$list{"Protein"}} ))
			{
				$wait="Protein";
				$f++;
			}
			elsif( grep( /$a/, @{$list{"DNA"}} ))
			{
				$wait="DNA";
				$f++;
			}
			elsif(grep( /$a/, @{$list{"RNA"}}))
			{
				$wait="RNA";
				$f++;
			}	
			else
			{	
				next;
			}	
			$seq="";
		}	
		else
		{
			chomp $line1;
			$seq.=$line1;
		}	
	}
	if($f!=0)
	{
		if(!(exists $sequence{$seq})) 
		{
			push(@{$sequence{$seq}},$wait);
			push(@{$sequence{$seq}},$a);
		}
		else
		{	
			push(@{$sequence{$seq}},$a);
 		}
	}	

	$nice=0;
	$unknown=0;

	for my $key (keys%sequence)#Push to MYSQL Databse
	{
		$a1="";
		$a2="";
		$a3="";
		$a4="";
		$a5="";
		$a6="";
		$a7="";
   		print $data.";".$sequence{$key}[0].";".$type.";".$res.";".$expt.";";
   		##print $sh $data.";".$sequence{$key}[0].";".$type.";".$res.";".$expt.";";
   
		$a1=$data;
   		$a2=$sequence{$key}[0];
   		$a3=$type;
   		$a4=$res;
   		$a5=$expt;
   		$a5=~ s/\;/\,/g;
	
   		if($sequence{$key}[0] eq "Protein")#Check for Protein Chain
   		{
    			$nice++;
   		}

		$len=@{$sequence{$key}};
		for($i=1;$i<$len;$i++)
		{
			print $sequence{$key}[$i];
			$a6.="$sequence{$key}[$i]";
			##print $sh $sequence{$key}[$i];

			if($i!=$len-1)
			{
				##print $sh ",";
				print ",";
				$a6.=",";
			}	
		}
		
		print ";".$key."\n";
		if($key=~ m/X+/)#Check for Unknown Residue
		{
			$unknown++;
		}
		$a7=$key;

		$stk =$dbh->prepare("insert into ChainDet values(?,?,?,?,?,?,?)");
		$stk->execute($a1,$a2,$a3,$a4,$a5,$a6,$a7);
	}


	if($unknown != 0 or $nice ==0)#Discard if no protein chains are present or unknown residues are present
	{
		$stk =$dbh->prepare("delete from ChainDet where PDB_ID=?");
		$stk->execute($data);
		$stk =$dbh->prepare("insert into rejected values (?)");
		$stk->execute(uc($data));
		print "not added to DB\n";
	}
	else
	{
		print "written to DB\n";
		$stk =$dbh->prepare("select *,count(Chain),group_concat(Chain separator '; '),sum(length(Chain) - length(replace(Chain,',',''))+1) from ChainDet where PDB_ID=? and Biomolecule=?");
		$stk->execute($data,"Protein");
		while (my @rec = $stk->fetchrow_array()) 
		{
			$na1=$rec[0];
			$na2=$rec[2];
			$na3=$rec[4];
			$na4=$rec[3];
			$na5=$rec[8];
			$na6=$rec[7];
			$na7=$rec[9];
		}	
		$na8=$rval1;
		$na8=$rval2 if $na8 ==0;
		print "$na1#$na2#$na3#$na4#$na5#$na6#$na7#$na8\n";
		$stk =$dbh->prepare("insert into mers values(?,?,?,?,?,?,?,?)");
		$stk->execute($na1,$na2,$na3,$na4,$na5,$na6,$na7,$na8);

	}
	$k++;
	print "Completed PDBid(s):".$k."\n";

}
close($fh);

