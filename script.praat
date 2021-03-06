##############################################################################
#   01  BOITE DE DIALOGUE
##############################################################################

form SYNTHÈSE VOCALE
    comment Entrez des mots à synthétiser: 
    comment Exemple: aujourd'hui les poussières anéantissent les montagnes
    text Mots aujourd'hui les poussières anéantissent les montagnes
    boolean Ajouter_Silence 
    comment Choisissez la modification prosodique :
    boolean F0
    boolean Duree
    comment Nommez le fichier final (*.wav): 
    word Nom myFile.wav
endform



##############################################################################
#   02  INITIALISATION DES VARIABLES DE FICHIER (FILE ARGUMENTS)
##############################################################################

fiTranscription = Read from file: "logatome-xu.TextGrid"
fiSon = Read from file: "logatome-xu.mp3"
tbDictionnaire=Read Table from tab-separated file: "dico.txt"
sonBase=Create Sound from formula: "sineWithNoise", 1, 0, 0.01, 44100, "0"

##############################################################################
#   03  SEGMENTATION DE SEQUENCE DE MOTS
#   04  TRANSFORMATION DES MOTS
##############################################################################

seqPhonetique$=""
seqOrtho$=mots$+" "

repeat
	indEspace = index(seqOrtho$, " ")
	motOrtho$ = left$(seqOrtho$, indEspace-1)
        
        if ( indEspace>0 )
	selectObject: 'tbDictionnaire'
        Extract rows where column (text): "orthographe", "is equal to", motOrtho$
        motPhonetique$ = Get value: 1, "phonetique"
        else
        motPhonetique$=""
        endif
        
        longueur = length(seqOrtho$)
	seqOrtho$ = right$(seqOrtho$, longueur-indEspace)
	seqPhonetique$ = seqPhonetique$ + motPhonetique$ 
until indEspace = 0


##############################################################################
#   04  SYNTHÈSE
##############################################################################
clearinfo
pause On va synthétiser /'seqPhonetique$'/

printline *******************************************************************

if ( ajouter_Silence )
seqPhonetique$="_"+seqPhonetique$+"_"
endif


selectObject: 'fiTranscription'
nbIntervals=Get number of intervals: 1

for i from 1 to length(seqPhonetique$)-1
	diphone$ = mid$(seqPhonetique$, i, 2)
	printline Le diphone 'diphone$'

	for j from 1 to nbIntervals-1
		selectObject: 'fiTranscription'
		phoneme1$ = Get label of interval: 1, j
		phoneme2$ = Get label of interval: 1, j+1

		if (phoneme1$ = mid$(seqPhonetique$, i, 1) and phoneme2$ = mid$(seqPhonetique$, i+1, 1))
			
			ptDebut = Get starting point: 1, j
			ptMilieu = Get end point: 1, j
			ptFin = Get end point: 1, j+1			
			printline
			
			printline 'phoneme1$' [ 'ptDebut' : 'ptMilieu' ]
			miPhon1 = (ptDebut+ptMilieu)/2
			printline 'phoneme2$' [ 'ptMilieu' : 'ptFin' ]
			miPhon2 = (ptFin+ptMilieu)/2
					
			selectObject: 'fiSon'
			pp = To PointProcess (zeroes): 1, "yes", "no"		

			miPhone1_index = Get nearest index: miPhon1
                        tmiPhon1 = Get time from index: miPhone1_index
                        printline le milieu de  'phoneme1$' est : 'tmiPhon1'
                        
                        miPhone2_index = Get nearest index: miPhon2
                        tmiPhon2 = Get time from index: miPhone2_index
                        printline le milieu de  'phoneme2$' est : 'tmiPhon2'
                        
                        selectObject: 'fiSon'
                        monDiphone = Extract part: tmiPhon1, tmiPhon2, "rectangular", 1, "no"
			
			selectObject: 'sonBase'
			plusObject: 'monDiphone'
			sonBase=Concatenate
			printline *******************************************************************
		endif
	endfor
endfor

if ( f0 )
@manF
endif

if ( duree )
@manD
endif


##############################################################################
#   05  PROCÉDURE : MODIFICATION DE F0
##############################################################################

procedure manF

selectObject: 'sonBase'
endTime=Get end time
maniProso = To Manipulation: 0.01, 75, 600
modPitch = Extract pitch tier
Remove points between: 0, endTime
peak = endTime * 0.8
Add point: 0.01, 100
Add point: peak, 150
Add point: endTime, 120
select 'maniProso' 
plus 'modPitch' 
Replace pitch tier
select 'maniProso' 
sonBase = Get resynthesis (overlap-add)

endproc

##############################################################################
#   06  PROCÉDURE : MODIFICATION DE DURÉE
##############################################################################

procedure manD

selectObject: 'sonBase'
endTime=Get end time
maniProso = To Manipulation: 0.01, 75, 600
modDuree = Extract duration tier
Remove points between: 0, endTime
Add point: 0.01, 0.8
Add point: endTime, 1.5
select 'maniProso' 
plus 'modDuree' 
Replace duration tier
select 'maniProso' 
sonBase = Get resynthesis (overlap-add)

endproc


##############################################################################
#   07  SAUVEGARDER LE FICHIER FINAL
##############################################################################

selectObject: 'sonBase'
Save as WAV file: "'nom$'"







