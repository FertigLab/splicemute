configfile: "config.yaml"

rule get_reference_data:
    input:
        REF_DIR=config["REF_DIR"],
        GTF_URL=config["GTF_URL"],
        FASTA_URL=config["FASTA_URL"],
        GTF_FILE_GZ=config["GTF_FILE_GZ"],
        FASTA_FILE_GZ=config["FASTA_FILE_GZ"]
    shell:
        """
        mkdir {input.REF_DIR}
        cd {input.REF_DIR}
        wget {input.GTF_URL}
        gunzip {input.GTF_FILE_GZ}
        wget {input.FASTA_URL}
        gunzip {input.FASTA_FILE_GZ}
        """

rule make_txdb:
    input:
        REF_DIR=config["REF_DIR"],
        SPLICEMUTR_SCRIPTS=config["SPLICEMUTR_SCRIPTS"],
        GTF_FILE=config["GTF_FILE"]
    output:
        OUT_FILE=config["OUT_FILE"]
    shell:
        """
        conda activate miniconda3/envs/splicemutr

        {input.SPLICEMUTR_SCRIPTS}/make_txdb.R -o {input.REF_DIR}/{output.OUT_FILE} -g {input.REF_DIR}/{input.GTF_FILE}
        """
    
rule prepare_leafcutter_references:
    input:
        LEAF_DIR=config["LEAF_DIR"],
        GTF=["GTF"]
    output:
        ANN_DIR=["ANN_DIR"]
    shell:
        """
        {input.LEAF_DIR}/scripts/gtf_to_exons.R $GTF {ouput.ANN_DIR}/G026.exons.txt

        cd $ANN_DIR

        {input.LEAF_DIR}/leafviz/gtf2leafcutter.pl -o G026 {input.GTF)
        """

rule convert_fasta_twobit:
    input:
        REF_DIR=config["REF_DIR"],
        FA_TO_TWOBIT_EXEC=config["FA_TO_TWOBIT_EXEC"],
        FASTA_FILE=confi["convert_fasta_twobit"]["FASTA_FILE"]
    output:
        TWOBIT_FILE=["convert_fasta_twobit"]["TWOBIT_FILE"]
    shell:
        """
        {input.FA_TO_TWOBIT_EXEC} {input.REF_DIR}/{input.FASTA_FILE} {input.REF_DIR}/{output.TWOBIT_FILE}
        """
  
rule create_bsgenome:
    input:
        REF_DIR=config["REF_DIR"],
        SEED_FILE=config["SEED_FILE"],
        SPLICEMUTR_SCRIPTS=config["SPLICEMUTR_SCRIPTS"],
        BSGENOME=config["BSGENOME"]
    shell:
        """
        conda activate splicemutr
    
        cd {input.REF_DIR}
    
        {input.SPLICEMUTR_SCRIPTS}/forge_bsgenome.R -s {input.SEED_FILE}
    
        R CMD BUILD {input.BSGENOME}
        R CMD check {input.BSGENOME}.tar.gz
        R CMD INSTALL {input.BSGENOME}.tar.gz
        """