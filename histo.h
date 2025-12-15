/* ========================================
   histo.h - Fonctions pour histogrammes
   ======================================== */

#ifndef HISTO_H
#define HISTO_H

// Traiter la capacité maximale des usines
int process_max(const char *input_file, const char *output_file);

// Traiter le volume total capté par les sources
int process_src(const char *input_file, const char *output_file);

// Traiter le volume réellement traité (avec fuites)
int process_real(const char *input_file, const char *output_file);

#endif
