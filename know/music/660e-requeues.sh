#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"
find $link -maxdepth 1 -type f -name \*mp3 \
    | sed "s=${link}/==" \
    | sort >660e-requeues-all.txt
sed -e '
        s/_^/ _^/
        s/,/ /
        s/_sous_des_Dominos_pourpres_et_feuilles_mortes//
        s/_And_His_Orchestra_With_Alice_Roberts//
        s/_Gavotte_garment_et_gracieusement//
        s/_et_tres_proprement//
        s/_-_Tendrement_-_Gayment//
        s/Musette_Rondeau_gracieusement/Musette_Rondeau/
        s/_sous_le_Domino_gris_de_maure//
        s/_et_ancienne_Mxnstrxndxsx//
        s/_Mxnstrxndxsx_1er_acte//
        s/_couleur_d_invisible//
        s/_sous_le_Domino_noir//
        s/_sous_des_Dominos_jaunes//
        s/_by_Jean-Baptiste_Forqueray/_by_Jean-Baptiste/
        s/La_sole_ou_Passacaille_Lente/Passacaille_Lente/
        s/_et_les_tresorieres_suranees/_et_les_suranees/
        s/_sous_le_Domino_gris_de_lin/_sous_le_Domino/
        s/Noblement_et_avec_Sentiment/Noblement/
        s/_And_His_Orchestra_With_/_with/
        s/La_Parisienne_Tres_legerement/La_Parisienne/
        s/Gavotte_en_Rondeau_Double/Gavotte_en_Rondeau_2x/
        s/Non_presto_ma_a_tempo_di_ballo/A_tempo_di_ballo/
        s/Les_Calotins_et_les_Calotines_ou_la_Piece_a_tretous/Les_Calotins_ou_la_Piece_a_tretous/
        s/La_Pudeur_sous_le_Domino_couleur_le_roze/La_Pudeur_sous_le_Domino_le_roze/
        s/Bob_Bobbin_Along-Ralph_Burns_Sessions-1955_58/Bob_Bobbin_Along/
        s/Back_To_Capistrano-Ralph_Burns_Sessions-1955_58/Back_To_Capistrano/
        s/And_Feathers_Tomorrow-Ralph_Burns_Sessions-1955_58/And_Feathers_Tomorrow/
        s/Les_jeunes_Seigneurs_Cy-devant_les_petits_Maitre/Les_jeunes_Seigneurs/
        s/Gmaj-Presto_quanto_sia_possible-Meyer/Gmaj-Presto-Meyer/
        s/Cmin-4_La_Boisson-Vivement_les_pinces_bien_soutenus/Cmin-4_La_Boisson-Vivement/
        s/in_Love-Hammerstein_II-Rodgers-Natural_Soul-1962/in_Love-Natural_Soul-1962/
        s/Pacifica-03_Suite_Dmaj-08_Fantaisie_Champestre/Pacifica-03_Suite_Dmaj-08_Fantaisie/
        s/Suitte-3_Sarabande_Tres_proprement/Suitte-3_Sarabande/
        s/Dmin-1_Sarabande_en_Rondeau/Dmin-1_Sarabande/
        s/15-Neufieme_Suitte-2_Courante_Affectueusement/15-Neufieme_Suitte-2_Courante/
        s/Suitte-2_Allemande_Pas_trop_viste/Suitte-2_Allemande/
        ' 660e-requeues-all.txt \
    | sort -f -k2 | column -t | sed -e 's/  / /' -e 's/  / /' >660e-requeues-artist.txt

