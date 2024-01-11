//
// Check input samplesheet and get read channels
//

include { QUALIMAP_RNASEQ }                            from '../../modules/nf-core/modules/qualimap/rnaseq/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_FOR_QC }    from '../../modules/nf-core/modules/samtools/index/main'
include { PICARD_COLLECTRNASEQMETRICS }                 from '../../modules/local/picard/collectrnaseqmetrics/main'
include { PICARD_MARKDUPLICATES }                      from '../../modules/nf-core/modules/picard/markduplicates/main'

workflow QC_WORKFLOW {
    take:
        bam_sorted
        ch_chrgtf
        ch_refflat

    main:
        ch_versions = Channel.empty()
        ch_qualimap_qc = Channel.empty()

        QUALIMAP_RNASEQ(bam_sorted, ch_chrgtf)
        ch_versions = ch_versions.mix(QUALIMAP_RNASEQ.out.versions)
        ch_qualimap_qc = QUALIMAP_RNASEQ.out.results.ifEmpty(null)

        SAMTOOLS_INDEX_FOR_QC(bam_sorted)
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX_FOR_QC.out.versions)

        bam_indexed = bam_sorted.join(SAMTOOLS_INDEX_FOR_QC.out.bai)

        PICARD_COLLECTRNASEQMETRICS(bam_indexed, ch_refflat, [])
        ch_versions = ch_versions.mix(PICARD_COLLECTRNASEQMETRICS.out.versions)

        PICARD_MARKDUPLICATES(bam_sorted)
        ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions)

    emit:
        versions            = ch_versions.ifEmpty(null)
        qualimap_qc         = ch_qualimap_qc.ifEmpty(null)
        rnaseq_metrics      = PICARD_COLLECTRNASEQMETRICS.out.metrics
        duplicate_metrics   = PICARD_MARKDUPLICATES.out.metrics

}

