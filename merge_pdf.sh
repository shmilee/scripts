#!/usr/bin/env bash

################################################################################
# Purpose:  Merge pdf file downloaded from Wanfang dissertation database
#               (http://g.wanfangdata.com.cn/)
# Author:   Xiao Hanyu(xiaohanyu1988@gmail.com)
# Depends:
#       pdftk:              merge multiple pdf files, pdftk is also a useful pdf 
#                               manipulation tools
#       ps2pdf/pdftops:     pdf --> ps then ps --> pdf to remove encryption 
################################################################################

function usage
{
    cat << EOF
`basename $0`: A utility to merge encryted pdf files into one single pdf

Usage:      `basename $0` [Options]
Example:    
            `basename $0` -f "file1.pdf file2.pdf" -o merged.pdf
            `basename $0` -d input_pdf_dir -o merged.pdf
            `basename $0` -d input_pdf_dir
Options:
    -f:     set the input pdf file list
    -d:     set the input pdf directory
    -o:     set the output pdf filename
    -h:     show this help
EOF
}

function merge_pdfs
{
    echo "######## Convert begin!! ########"
    for pdf in $pdf_list
    do
        ## do not use pdf_name = `basename $pdf .pdf` 
        ## since basename will remove the directory prefix of $pdf
        pdf_name=`echo $pdf | sed -e "s/\.pdf//"`

        ## add some animation ^_^
        echo -n "$pdf_name.pdf ---->> $pdf_name.ps "
        pdftops $pdf_name.pdf $pdf_name.ps

        echo "---->> $pdf_name.pdf"
        ps2pdf $pdf_name.ps $pdf_name.pdf
        rm -rf $pdf_name.ps
    done
    echo "######## Convert end!! ########"

    echo "######## Merge begin!! ########"
    pdftk $pdf_list cat output $pdf_merge
    echo "######## Merge success, open $pdf_merge to see the result. Bye!! ########"
}

while getopts "d:f:o:h" arg
do 
    case $arg in
        d)
            pdf_dir=$OPTARG
            pdf_list=`ls $pdf_dir/*pdf`
            ;;
        f) 
            pdf_list=$OPTARG
            ;;
        o) 
            pdf_merge=$OPTARG
            ;;
        h)  
            usage
            exit 0
            ;;
        ?)
            echo "!!Wrong command options"
            usage
            exit 1
            ;;
    esac
done

# if pdf_dir is not set yet, then it's set to default(that is, current directory)
pdf_dir=${pdf_dir:-"."}

# set default output pdf filename, plus $pdf_dir prefix
pdf_merge="${pdf_dir}/${pdf_merge:-"single_merged_pdf.pdf"}"
merge_pdfs