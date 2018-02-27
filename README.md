# PDB-Scrapper
Web Crawler to Extract data from PDB(Protein Data Bank) Files.

### Software Requirements(in Fedora(i.e Linux) OS):
- **Perl**
 * Modules Required(Can be installed using [CPAN](https://www.cpan.org/):
   1. DBI (for Connecting to Database)]
   2. LWP::Simple (for Web Crawling)
   3. IO::String (for Web Crawling)

- *MySQL Server*


### Features of the crawler

-The perl is capable of extracting the following information:
1. Experiment Type(Eg.X-Ray Diffraction,NMR)
2. Protein Type(Eg.Lectin)
3. Resolution of the structure
4. R-factor

-For each Individual Chain in a structure,the code determines:
1. Type of the chain(Protein/DNA/RNA)
2. Primary Sequence(from the FASTA file)

-The code discards the extract data on the following conditions:

1. The Chain contains any unknown residue
2. There is no protein chains in the structure(only DNA or/and RNA)



