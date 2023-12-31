import pickle
import os
os.environ['OPENBLAS_NUM_THREADS'] = '10'
import glob

configfile: 'config.yaml'

###IMPORTENT###
#file_path = config["file_path"]
# all the 
chrom = config["chromosomes"]
length = config["chromosome_length"]
datasets = config["datasets"]
blacklist = config["blacklist"]
exons = config["exons"]

#genome_bed = config["genome_bed"]
#topmed = config["topmed_data"] # when i want to start filtering 
#coverage_files = config["coverage"] # use this to make bedfiles, maybe later
window_sizes = config["window_size_mb"]
kmer_indels = config["kmer_indels"]
NumberWithDepth = config["NumberWithDepth"]
two_bit = config["twobitgenome"]
allelefrequency = config["allelefrequency"]
signatures = config["NumberOfSignatures"]
pattern_type = config["pattern_type"]
size_partition = config["size_partition"]
# methylation_data = config["methylation_data"]
# replication_time = config["replication_time"]
# size_partition = config["size_partition"]
# complex_structure = config["complex_structure"]
# recombination = config["recombination"]

#this makes the wildcards of the regions i want to investigate
def making_windows(chromosomes, length, window_sizes):
	regions = []
	for window_size in window_sizes:
		size = window_size*1000000 # for an indel analysis only windows with the size of 10^6 is doable
		for chrom in chromosomes:
			for pos in range(size, int(length[chrom]), size):
				title = chrom+"_"+str(int((pos-size)/1000000))+"mb_to_"+str(int(pos/1000000))+"mb"
				regions.append(title)
	return regions

# Check if the file exists
if os.path.exists("regions.pkl"):
    # Load the list from the file
    with open("regions.pkl", "rb") as file:
        regions = pickle.load(file)
else:
	os.makedirs("1mb_windows/regions/")
	regions = making_windows(chrom, length, window_sizes)
	for region in regions:
		print(region)
		chrom = region.split("_")[0].split("m")[0]
		start = str(int(region.split("_")[1].split("m")[0])*1000000)
		end = str(int(region.split("_")[3].split("m")[0])*1000000)
		filename = f"1mb_windows/regions/{region}.bed"
		with open(filename, "w") as file:
			file.write(f"{chrom}\t{start}\t{end}\n")
	with open("regions.pkl", "wb") as file:
		pickle.dump(regions, file)

def creating_breakpoints(kmer):
	before = int(kmer)/2
	after = before-1
	return [before, after]

# def making_windows2(chromosome, length, window_size):
# 	regions = []
# 	size = window_size*1000000
# 	for pos in range(size, int(length[chrom]), size):
# 		title = str(int((pos-size)/1000000))+"mb_to_"+str(int(pos/1000000))+"mb"
# 			regions.append(title)
# 	return regions
rule all:
	input:
		expand(["files/{datasets}/coverage_files/{chrom}.BRAVO_TOPMed_coverage_hg38.txt.gz",
		"files/{datasets}/derived_files/accepted_coverage/{chrom}x10_{fraction}p.bed", # This file contains a bedfile of all the regions that passes the restriction i have put on 80% of the individuals needs to have a coverage of 10x
		"files/{datasets}/derived_files/accepted_coverage/all_coverage_x10_{fraction}p.bed",
		"files/{datasets}/vcf_files/{chrom}.BRAVO_TOPMed_Freeze_8.vcf.gz",
		"files/{datasets}/derived_files/vcf_indels/{chrom}_indel_{freq}.vcf.gz",
		"files/{datasets}/derived_files/vcf_indels/all_indels_{freq}.vcf.gz",
		"{window_sizes}mb_windows/regions/{region}.bed",
		"{window_sizes}mb_windows/filtered_regions_{fraction}p/{region}.bed",
		"{window_sizes}mb_windows/background_{kmer}mer/background_{region}_{kmer}mer_{fraction}p.bed",
		"{window_sizes}mb_windows/variants/indels_{region}_{freq}_{fraction}p.bed", # can be removed # no it shouldnt 
		"{window_sizes}mb_windows/variants/ins_{region}_{freq}_{fraction}p.bed",
		"{window_sizes}mb_windows/variants/del_{region}_{freq}_{fraction}p.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/ins_counts_{region}_{kmer}mer.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/del_counts_{region}_{kmer}mer.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_counts_{kmer}mer.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_counts_{kmer}mer.bed", 
		"{window_sizes}mb_windows/background_{kmer}mer/combined/background_{kmer}mer_{fraction}p.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_size_{kmer}mer.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_size_{kmer}mer.bed",
		"{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{kmer}mer/ins_size_{region}_{size_partition}.bed",
		"{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{kmer}mer/del_size_{region}_{size_partition}.bed",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/insertions_dataframe_{kmer}mer.rds", # types
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/deletions_dataframe_{kmer}mer.rds", # types
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/merged_dataframe_{kmer}mer.rds",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_size_dataframe_{kmer}mer.rds",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_size_dataframe_{kmer}mer.rds",
		"{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/merged_size_dataframe_{kmer}mer.rds", # types
		"{window_sizes}mb_windows/models/frequency_{freq}_at_{fraction}p/{types}_{kmer}mer/{types}_{kmer}mer_{signatures}.rds"
		], datasets = datasets, chrom = chrom, fraction = NumberWithDepth, freq = allelefrequency,
		region = regions, window_sizes = window_sizes, kmer = kmer_indels, types = pattern_type,
		signatures = signatures, size_partition = size_partition) #region = regions, window_sizes = window_sizes, kmer = kmer_indels,chrom = chrom, fraction = NumberWithDepth, freq = allelefrequency, size_partition = size_partition, complex_structure = complex_structure)

rule coverage_regions:
	input:
		seq_zipped = "files/{datasets}/coverage_files/{chrom}.BRAVO_TOPMed_coverage_hg38.txt.gz"
	params: 
		procent = lambda wildcards: float(int(wildcards.fraction)/100)
	resources:
		threads=4,
		time=120,
		mem_mb=5000
	output:
		bedfile = "files/{datasets}/derived_files/accepted_coverage/{chrom}x10_{fraction}p.bed" # This file contains a bedfile of all the regions that passes the restriction i have put on 80% of the individuals needs to have a coverage of 10x
	shell:"""
	temp_unzipped=$(mktemp -u)
    gunzip -c {input.seq_zipped} > $temp_unzipped
	python scripts/countingregions.py $temp_unzipped {params.procent} > {output.bedfile}
	gzip $temp_unzipped
	"""
rule vcf_indel:
	input:
		raw_vcf = "files/{datasets}/vcf_files/{chrom}.BRAVO_TOPMed_Freeze_8.vcf.gz"
	conda: "envs/bcftools.yaml"
	output:
		filtered = "files/{datasets}/derived_files/vcf_indels/{chrom}_indel_{freq}.vcf.gz",
	shell:"""
	tabix -f -p vcf {input.raw_vcf}
	bcftools filter -O z -o {output.filtered} -i 'AF<{wildcards.freq} && VRT=2' {input.raw_vcf}
	"""


# ### These two tricks uses blast which have the snakefile crash sometimes on the cluster
for dataset in datasets:
    for fraction in NumberWithDepth:
        if not os.path.exists(f"files/{dataset}/derived_files/accepted_coverage/all_coverage_x10_{fraction}p.bed"):
            os.system(f"cat files/{dataset}/derived_files/accepted_coverage/chr*x10_{fraction}p.bed > files/{dataset}/derived_files/accepted_coverage/all_coverage_x10_{fraction}p.bed")

for dataset in datasets:
    for frequency in allelefrequency:
        if not os.path.exists(f"files/{dataset}/derived_files/vcf_indels/all_indels_{frequency}.vcf.gz"):
            os.system(f"cat files/{dataset}/derived_files/vcf_indels/chr*_indel_{frequency}.vcf.gz > files/{dataset}/derived_files/vcf_indels/all_indels_{frequency}.vcf.gz")

# rule aggregate_chromosomes:
# 	input:
# 		#individual_coverage = "files/{datasets}/derived_files/accepted_coverage/{chrom}x10_{fraction}p.bed",
# 		individual_vcf =  expand("files/{datasets}/derived_files/vcf_indels/{chrom}_indel_{{freq}}.vcf.gz", chrom = chrom, freq = allelefrequency, datasets = datasets)
# 	output:
# 		#summary_coverage = "files/{datasets}/derived_files/accepted_coverage/all_coverage_x10_{fraction}p.bed",
# 		summary_vcf= "files/{datasets}/derived_files/vcf_indels/all_indels_{{freq}}.vcf.gz"
# 	shell:"""
# #	cat {input.individual_coverage} > {output.summary_coverage}
# 	cat {input.individual_vcf} > {output.summary_vcf}
# 	"""

# a rule which makes the MegaBases bedfile 
# Creating regions which are to be investigated
# rule mega_bases:
# 	params: 
# 		chrom = lambda wildcards: wildcards.region.split("_")[0].split("m")[0],
# 		start = lambda wildcards: str(int(wildcards.region.split("_")[1].split("m")[0])*1000000),
# 		end = lambda wildcards: str(int(wildcards.region.split("_")[3].split("m")[0])*1000000)
# 	resources:
# 		threads=1,
# 		time=1,
# 		mem_mb=100
# 	output:
# 		bedfiles = "{window_sizes}mb_windows/regions/{region}.bed"
# 	shell:"""
# 	printf '%s\t%s\t%s\n' {params.chrom} {params.start} {params.end} > {output.bedfiles}
# 	"""
#the fitlers for regions are blacklist(add ref), average coverage, and i want to add exome as well
#last couple of lines is accepting the regins, in which more then 50% of the bases are not filtered away
rule filtering_regions:
	input:
		regions = "{window_sizes}mb_windows/regions/{region}.bed",
		coverage_accepted = "files/topmed/derived_files/accepted_coverage/all_coverage_x10_{fraction}p.bed", # this is a stupid idea
		blacklist = blacklist,
		exons = exons
	conda: "envs/bedtools.yaml"
	resources:
		threads=1,
		time=60,
		mem_mb=5000 #this can be put waaay down, im just afraid of triggering snakemake to make the files again
	output:
		tmp_cov = temporary("{window_sizes}mb_windows/tmp/tmp_coverage_{region}_{fraction}p.bed"),
		tmp_blacklist = temporary("{window_sizes}mb_windows/tmp/blacklist_{region}_{fraction}p.bed"),
		tmp_exons = temporary("{window_sizes}mb_windows/tmp/exons_{region}_{fraction}p.bed"),
		filtered_regions = "{window_sizes}mb_windows/filtered_regions_{fraction}p/{region}.bed"
	shell:"""
	bedtools intersect -a {input.regions} -b {input.coverage_accepted} > {output.tmp_cov}
	bedops --partition <(sort-bed {output.tmp_cov}) <(sort-bed {input.blacklist}) | bedops --not-element-of 1 - <(sort-bed {input.blacklist}) > {output.tmp_blacklist}
	bedops --partition <(sort-bed {output.tmp_blacklist}) <(sort-bed {input.exons}) | bedops --not-element-of 1 - <(sort-bed {input.exons}) > {output.tmp_exons}
	tmp=`cat {output.tmp_exons} | awk '{{s += ($3-$2)}} END {{print s}}'`
	num=$(expr {window_sizes} \* 1000000 / 2)
	if [[ $tmp -ge $num ]]
	then 
		cp {output.tmp_exons} {output.filtered_regions}
	else
		touch {output.filtered_regions}
	fi
	"""

rule indel_background_counter: #im not sure this works
	input:
		filtered_regions = "{window_sizes}mb_windows/filtered_regions_{fraction}p/{region}.bed",
		genome = two_bit
	conda: "envs/kmer_counter.yaml"
	params:
		before_break  = lambda wildcards: int(creating_breakpoints(wildcards.kmer)[0]),
		after_break = lambda wildcards: int(creating_breakpoints(wildcards.kmer)[1])
	output:
		background = temporary("{window_sizes}mb_windows/tmp/background_{region}_{kmer}mer_{fraction}p.bed"),
		ss_background = "{window_sizes}mb_windows/background_{kmer}mer/background_{region}_{kmer}mer_{fraction}p.bed"
	shell:"""
	check=`cat {input.filtered_regions} | wc -l`
	if [[ $check -gt 0 ]]
	then 
		kmer_counter background --bed {input.filtered_regions} --before_after {params.before_break} {params.after_break} --reverse_complement_method both {input.genome} > {output.background}
		awk -v OFS='\t' '{{print "{wildcards.region}",$1,$2}}' {output.background} > {output.ss_background}
	else
		touch {output.background}
		touch {output.ss_background}
	fi
	"""

rule creating_indel_variants:
	input:
		filtered_regions = "{window_sizes}mb_windows/filtered_regions_{fraction}p/{region}.bed",
		vcf_file = "files/topmed/derived_files/vcf_indels/all_indels_{freq}.vcf.gz", # this is a stupid idea
	conda: "envs/bedtools.yaml"
	output:
		variants =  "{window_sizes}mb_windows/variants/indels_{region}_{freq}_{fraction}p.bed",
		ins_variants = "{window_sizes}mb_windows/variants/ins_{region}_{freq}_{fraction}p.bed",
		del_variants = "{window_sizes}mb_windows/variants/del_{region}_{freq}_{fraction}p.bed"
	shell:"""
	check=`cat {input.filtered_regions} | wc -l`
	if [[ $check -gt 0 ]]
	then
		bedtools intersect -a {input.vcf_file} -b {input.filtered_regions} | awk -v OFS='\t' '{{print $1,$2,$4,$5}}' > {output.variants}
	else
		touch {output.variants}
	fi
	python scripts/creating_deletions.py {output.variants} > {output.del_variants}
	python scripts/creating_insertions.py {output.variants} > {output.ins_variants}
	"""

rule indel_variant_counter:
	input:
		ins_variants = "{window_sizes}mb_windows/variants/ins_{region}_{freq}_{fraction}p.bed",
		del_variants = "{window_sizes}mb_windows/variants/del_{region}_{freq}_{fraction}p.bed",
		genome = two_bit
	conda: "envs/kmer_counter.yaml"
	params:
		radius  = lambda wildcards: int(int(wildcards.kmer)/2)
	output:
		kmer_count_ins = temporary("{window_sizes}mb_windows/tmp/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/ins_counts_{region}_{kmer}mer.bed"),
		kmer_count_del = temporary("{window_sizes}mb_windows/tmp/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/del_counts_{region}_{kmer}mer.bed"),
		ss_ins = "{window_sizes}mb_windows/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/ins_counts_{region}_{kmer}mer.bed",
		ss_del = "{window_sizes}mb_windows/indels_{kmer}mer/frequency_{freq}_at_{fraction}p/del_counts_{region}_{kmer}mer.bed"
	shell:"""
	check=`cat {input.ins_variants} | wc -l`
	if [[ $check -gt 0 ]]
	then
		kmer_counter indel -r {params.radius} --sample {input.genome} {input.ins_variants} ins > {output.kmer_count_ins}
		kmer_counter indel -r {params.radius} --sample {input.genome} {input.del_variants} del_start > {output.kmer_count_del}
		awk -v OFS='\t' '{{print "{wildcards.region}",$1,$2}}' {output.kmer_count_ins} > {output.ss_ins} 
		awk -v OFS='\t' '{{print "{wildcards.region}",$1,$2}}' {output.kmer_count_del} > {output.ss_del}
	else
		touch {output.kmer_count_del}
		touch {output.kmer_count_ins}
		touch {output.ss_del}
		touch {output.ss_ins} 
	fi
	"""
rule size_variant_indel:
	input:
		ins_variants = "{window_sizes}mb_windows/variants/ins_{region}_{freq}_{fraction}p.bed",
		del_variants = "{window_sizes}mb_windows/variants/del_{region}_{freq}_{fraction}p.bed"
	params:
		#size = lambda wildcards: ",".join(wildcards.size_partition.split(","))
	output:
		insertion = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/variant/size/ins_size_{region}_{size_partition}.bed",
		deletion = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/variant/size/del_size_{region}_{size_partition}.bed"
	shell:"""
	check=`cat {input.ins_variants} | wc -l`
	echo "$check"
	if [[ $check -gt 0 ]]
	then
		echo {wildcards.size_partition}
		python scripts/splitting_indel_size.py {input.ins_variants} {wildcards.size_partition} > {output.insertion}
		python scripts/splitting_indel_size.py {input.del_variants} {wildcards.size_partition} > {output.deletion}
	else
		touch {output.insertion}
		touch {output.deletion}
	fi
	"""
rule size_counts_indel:
	input:
		insertion = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/variant/size/ins_size_{region}_{size_partition}.bed",
		deletion = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/variant/size/del_size_{region}_{size_partition}.bed",
		genome = two_bit
	conda: "envs/kmer_counter.yaml"
	params:
		radius  = lambda wildcards: int(int(wildcards.kmer)/2)
	output:
		insertion_size_ss = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{kmer}mer/ins_size_{region}_{size_partition}.bed",
		deletion_size_ss = "{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{kmer}mer/del_size_{region}_{size_partition}.bed"
	shell:"""
	check=`cat {input.insertion} | wc -l`
	echo "$check"
	if [[ $check -gt 0 ]]
	then
		kmer_counter indel -r {params.radius} --sample {input.genome} {input.insertion} ins | awk -v OFS='\t' '{{print "{wildcards.region}","{wildcards.size_partition}",$1,$2}}' - > {output.insertion_size_ss} 
		kmer_counter indel -r {params.radius} --sample {input.genome} {input.deletion} del_start | awk -v OFS='\t' '{{print "{wildcards.region}","{wildcards.size_partition}",$1,$2}}' - > {output.deletion_size_ss}
		
	else
		touch {output.insertion_size_ss}
		touch {output.deletion_size_ss}
	fi
	"""
##Make a check for the directories

# rule aggregate_indels_regions:
# 	input:
# 		insertions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/frequency_{freq}_at_{fraction}p/ins_counts_{region}_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, region = regions, window_sizes = window_sizes, kmer = kmer_indels),
# 		deletions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/frequency_{freq}_at_{fraction}p/del_counts_{region}_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, region = regions, window_sizes = window_sizes, kmer = kmer_indels),
# 		background = expand("{window_sizes}mb_windows/background_{{kmer}}mer/background_{region}_{{kmer}}mer_{fraction}p.bed", fraction = NumberWithDepth, freq = allelefrequency, region = regions, window_sizes = window_sizes, kmer = kmer_indels)
# 	output:
# 		summary_insertions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/combined/frequency_{freq}_at_{fraction}p/ins_counts_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, window_sizes = window_sizes, kmer = kmer_indels),
# 		summary_deletions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/combined/frequency_{freq}_at_{fraction}p/del_counts_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, window_sizes = window_sizes, kmer = kmer_indels),
# 		summary_background = expand("{window_sizes}mb_windows/background_{{kmer}}mer/combined/background_{{kmer}}mer_{fraction}p.bed", fraction = NumberWithDepth, freq = allelefrequency, window_sizes = window_sizes, kmer = kmer_indels)
# 	params:
# 	shell:"""
# 	cat {input.insertions} >> {output.summary_insertions}
# 	cat {input.deletions} >> {output.summary_deletions}
# 	cat {input.background} >> {output.summary_background}
# 	"""

# rule aggregate_size_indels:
# 	input:
# 		insertions = expand("{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{{kmer}}mer/ins_size_{region}_{size_partition}.bed", fraction = NumberWithDepth, freq = allelefrequency, region = regions, window_sizes = window_sizes, kmer = kmer_indels, size_partition = size_partition),
# 		deletions = expand("{window_sizes}mb_windows/size_difference_{freq}_{fraction}p/counts_{{kmer}}mer/del_size_{region}_{size_partition}.bed", fraction = NumberWithDepth, freq = allelefrequency, region = regions, window_sizes = window_sizes, kmer = kmer_indels, size_partition = size_partition)
# 	output:
# 		summary_insertions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/combined/frequency_{freq}_at_{fraction}p/ins_size_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, window_sizes = window_sizes, kmer = kmer_indels),
# 		summary_deletions = expand("{window_sizes}mb_windows/indels_{{kmer}}mer/combined/frequency_{freq}_at_{fraction}p/del_size_{{kmer}}mer.bed", fraction = NumberWithDepth, freq = allelefrequency, window_sizes = window_sizes, kmer = kmer_indels)
# 	params:
# 	shell:"""
# 	cat {input.insertions} >> {output.summary_insertions}
# 	cat {input.deletions} >> {output.summary_deletions}
# 	"""

for window_size in window_sizes:
	for fraction in NumberWithDepth:
		for frequency in allelefrequency:
			for kmer in kmer_indels:
				if not os.path.exists(f"{window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/ins_counts_{kmer}mer.bed"):
					os.system(f"cat {window_size}mb_windows/indels_{kmer}mer/frequency_{frequency}_at_{fraction}p/ins_counts_*_{kmer}mer.bed > {window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/ins_counts_{kmer}mer.bed")
				if not os.path.exists(f"{window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/del_counts_{kmer}mer.bed"):
					os.system(f"cat {window_size}mb_windows/indels_{kmer}mer/frequency_{frequency}_at_{fraction}p/del_counts_*_{kmer}mer.bed > {window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/del_counts_{kmer}mer.bed")
				if not os.path.exists(f"{window_size}mb_windows/background_{kmer}mer/combined/background_{kmer}mer_{fraction}p.bed"):
					os.system(f"cat {window_size}mb_windows/background_{kmer}mer/background_*_{kmer}mer_{fraction}p.bed > {window_size}mb_windows/background_{kmer}mer/combined/background_{kmer}mer_{fraction}p.bed")


for window_size in window_sizes:
	for fraction in NumberWithDepth:
		for frequency in allelefrequency:
			for kmer in kmer_indels:
					if not os.path.exists(f"{window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/ins_size_{kmer}mer.bed"):
						os.system(f"cat {window_size}mb_windows/size_difference_{frequency}_{fraction}p/counts_{kmer}mer/ins_size_*.bed > {window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/ins_size_{kmer}mer.bed")
					if not os.path.exists(f"{window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/del_size_{kmer}mer.bed"):
						os.system(f"cat {window_size}mb_windows/size_difference_{frequency}_{fraction}p/counts_{kmer}mer/del_size_*.bed > {window_size}mb_windows/indels_{kmer}mer/combined/frequency_{frequency}_at_{fraction}p/del_size_{kmer}mer.bed")




# ###Now let do some nmf###

rule prepare_for_nmf:
	input:
		summary_insertions = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_counts_{kmer}mer.bed",
		summary_deletions = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_counts_{kmer}mer.bed",
		summary_background = "{window_sizes}mb_windows/background_{kmer}mer/combined/background_{kmer}mer_{fraction}p.bed"
	conda: "envs/callr.yaml"
	output:
		insertions_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/insertions_dataframe_{kmer}mer.rds",
		deletions_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/deletions_dataframe_{kmer}mer.rds",
		merged_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/merged_dataframe_{kmer}mer.rds"
	shell:"""
	Rscript scripts/creating_dataframes.R {input.summary_background} {input.summary_insertions} {input.summary_deletions} {output.deletions_dataframe} {output.insertions_dataframe} {output.merged_dataframe}
	"""

rule prepare_for_nmf_sizeindels:
	input:
		summary_insertions = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_size_{kmer}mer.bed",
		summary_deletions = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_size_{kmer}mer.bed",
		summary_background = "{window_sizes}mb_windows/background_{kmer}mer/combined/background_{kmer}mer_{fraction}p.bed"
	conda: "envs/callr.yaml"
	output:
		insertions_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/ins_size_dataframe_{kmer}mer.rds",
		deletions_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/del_size_dataframe_{kmer}mer.rds",
		merged_dataframe = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/merged_size_dataframe_{kmer}mer.rds"
	shell:"""
	Rscript scripts/creating_dataframes_sizedifference.R {input.summary_background} {input.summary_insertions} {input.summary_deletions} {output.deletions_dataframe} {output.insertions_dataframe} {output.merged_dataframe}
	"""

rule modelselection:
	input:
		count_data = "{window_sizes}mb_windows/indels_{kmer}mer/combined/frequency_{freq}_at_{fraction}p/{types}_dataframe_{kmer}mer.rds"
	conda: "envs/nmf.yaml"
	resources:
		threads=4,
		time=540,
		mem_mb=8000
	output:
		model = "{window_sizes}mb_windows/models/frequency_{freq}_at_{fraction}p/{types}_{kmer}mer/{types}_{kmer}mer_{signatures}.rds"
	shell:"""
    Rscript scripts/opportunity_modelselection.R {wildcards.signatures} {input.count_data} {output.model}
    """
### Types is not implemented across all wildcards