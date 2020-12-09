#!/bin/bash

clear;
echo "Bash version ${BASH_VERSION}";

user="$(whoami)"
cd /home/"$user";

if test -d "SQL"
then
    cd SQL;
else
        mkdir SQL;
        cd SQL;
fi
db_open=0;
echo  -ne "$user$>";
read -a command;

#------------------DONE------------------#
function CREATE(){


        if [ "${command[1]}" == "TABLE" ]
        then
                if test -f "${command[2]}";
                then
            echo -ne "Exista deja o tabela cu acest nume!\n"
        else
                touch "${command[2]}";

                len=${#command[@]};

                for (( i=4; i<$len; i=i+2 ))
                        do
                             echo -ne "${command[i]} " >> "${command[2]}";
                        done

                        echo -ne "\n" >> "${command[2]}";

                        for (( i=3; i<$len; i=i+2 ))
                        do
                                echo -ne "${command[i]} " >> "${command[2]}";
                        done

                        echo -ne "\n" >> "${command[2]}";

                        echo -ne "Tabela ${command[2]} a fost creata cu succes!\n";

        fi
    else
        if [ "${command[1]}" == "DB" ]
        then
                if test -d "${command[2]}";
                        then
                    echo -ne "Exista deja o baza de date cu acest nume!\n"
                else
                        mkdir "${command[2]}";
                        echo -ne "Baza de date ${command[1]} a fost creata cu succes!\n"
                fi
        fi
        fi
}
#----------------------------------------#



#------------------DONE------------------#
function OPEN(){

    if test -d "$1";
    then
        cd "$1";
        target="$(pwd)"

        if [ -z "$(ls -A $target)" ]; then

                echo "Ati accesat baza de date $1!"
        else


                for f in "$target"/*
                do
                        name=$(echo "$f" | cut -f 1 -d '.')
                        openssl enc -aes-256-cbc 2>/dev/null  -d -in "$f" > "$name" -pass pass:"paroleparole"
                        rm "$f"

                done
                echo -ne "Ati accesat baza de date $1! Datele au fost decriptate!\n";
        fi
    else
        echo -ne "Baza de date $1 nu exista\n";
    fi
}
#----------------------------------------#


#------------------DONE------------------#
function CLOSE(){

   # cd /home/"$user"/SQL;
    if [ "$1" == "DB" ]
    then

        target="$(pwd)"

        if [ -z "$(ls -A $target)" ]; then

                echo "Ati iesit din  baza de date $1!"
                cd /home/"$user"/SQL
        else

        for f in "$target"/*
                do
                        openssl enc -aes-256-cbc 2>/dev/null  -in "$f" -out "$f.enc" -pass pass:"paroleparole"
                        rm "$f"

                done
        cd /home/"$user"/SQL;
        echo "Ati iesit din baza de date!";
        fi


    fi

}
#----------------------------------------#


#------------------DONE------------------#
function UPDATE(){

        declare -a colls_to_be_upd;                     #salvarea coloanelor ce trebuie modificate

        declare -a index_colls_to_be_upd;               #indexum coloanelor ce trebuie modificate

        declare -a upd_vals;                                    #valorile noi

        declare -a colls_cond;                                  #salvarea coloanelor ce reprezinta conditii

        declare -a cond_val;                                    #valoarea conditiilor

        declare -a collumns;                                    #retin 'header-ul' table-ului

        declare -a datatypes;

        RED='\033[0;31m'
        NC='\033[0m'

        if test -f "${command[1]}"; then #verificare daca exista fisierul

        #tail -n +2 "${command[1]}"

        collumns=($(sed '2!d' "${command[1]}")) #iau de pe linia 2 din fisier "header-ul" table-ului
        datatypes=($(sed '1!d' "${command[1]}")) #iau de pe prima linie a fisierului tupurile de date ale coloanelor
        #echo "${collumns[@]}"

        nr_colls="$(wc -w <<< "$(sed '2!d' "${command[1]}")")" #salvez numarul de coloane
        nr_rows="$(wc -l < "${command[1]}")" #salvez numarul de randuri
        (( nr_rows=nr_rows-2 )) #scad primele doua randuri care fac referire la
                                                                                                #tipurile de date ale coloanelor
                                                                                                #numele coloanelor


        index_whr=0; #indexul pozitiei pe care se afla 'WHERE'

        nr_words=0; #numarul de cuvinte din comanda

        if [ "${command[2]}" == "SET" ]; then
                ok_set=1;
        else
                echo -e ${RED}"Syntax error! Check help for more info on UPDATE command."${NC}
                return
        fi

        for txt in "${command[@]}" #parcurg comanda cuvant cu cuvant
        do

                if [ "$txt" == "WHERE" ]; then
                        index_whr="$nr_words" #cand gasesc "where" ii salvez pozitia
                fi
        (( nr_words=nr_words+1 )) #incrementez numarul de cuvinte
        done
        fi

        if [ $index_whr == 0 ]; then
                echo -e ${RED}"Syntax error! Check help for more info on UPDATE command."${NC}
                return
        fi

        nr_colls_tbu=0; #numarul de coloane ce urmeaza sa fie updatate
        for ((i = 3; i < index_whr; i=i+3)) #plec de la al 3-lea cuvant, $prima coloana: update table set col
        do
                colls_to_be_upd[nr_colls_tbu]=${command[$i]} #salvez valoarea in matrice

                upd_vals[nr_colls_tbu]="${command[$i+2]}" #sar peste egal si salvez valoarea ce urmeaza sa inlocuiasca

                ((nr_colls_tbu=nr_colls_tbu+1)) #incrementez numarul de coloane ce trebuie updatate
        done

        for((i = 0; i < nr_colls_tbu; ++i))
        do

                ok_colls_tbu=0;

                for((j = 0; j < nr_colls; ++j))
                do
                        if [ "${colls_to_be_upd[$i]}" == "${collumns[$j]}" ]; then


                                ok_colls_tbu=1;

                        fi
                done

                if [ $ok_colls_tbu -eq 0 ]; then
                        ok_update=0

                        echo -e ${RED}"Column to be updated '${colls_to_be_upd[$i]}' does not exist!"${NC}
                        return
                fi


        done

        nr_colls_cond=0 #numarul de coloane ce vor reprezenta restritiile pentru update
        for ((j = index_whr+1; j < nr_words; j=j+3))
        do
                colls_cond[nr_colls_cond]="${command[$j]}"

                cond_val[nr_colls_cond]="${command[$j+2]}"

                ((nr_colls_cond=nr_colls_cond+1))
        done

        for((i = 0; i < nr_colls_cond; ++i))
        do

                ok_colls_cond=0;

                for((j = 0; j < nr_colls; ++j))
                do
                        if [ "${colls_cond[$i]}" == "${collumns[$j]}" ]; then
                                ok_colls_cond=1;
                        fi
                done

                if [ $ok_colls_cond -eq 0 ]; then
                        ok_update=0

                        echo -e ${RED}"Column '${colls_cond[$i]}' from conditions does not exist!"${NC}
                        return
                fi

        done


        declare -a index_colls_with_cond #salvez indexul coloanelor pe care se pun conditii

        ok="false";
        temp_index=0;
        for ((i = 0; i < nr_colls; ++i)) #parcurg toate coloanele
        do

                ok="false";

                for ((j = 0; j < nr_colls_cond; ++j))
                do
                        if [ "${collumns[$i]}" == "${colls_cond[$j]}" ]; then
                                ok="true"

                        fi
                done

                if [ "$ok" == "true" ]; then
                        index_colls_with_cond[temp_index]="$i"
                        ((temp_index=temp_index+1))
                fi

        done

        for ((i = 0; i < nr_colls; ++i))
        do

                ok="false";

                for ((j = 0; j < nr_colls_tbu; ++j))
                do
                        if [ "${collumns[$i]}" == "${colls_to_be_upd[$j]}" ]; then
                                ok="true"

                        fi
                done

                if [ "$ok" == "true" ]; then
                        index_colls_to_be_upd[temp_index]="$i"
                        ((temp_index=temp_index+1))
                fi

        done


        declare -a row

        for ((i = 3; i <= $nr_rows+2; ++i)) #parcurg toate randurile incepand cu primul rand pe care se afla date
        do

                ok_update=0

                row=($(sed "${i}q;d" ${command[1]})) #salvez in variabila row randul i

                ok="true"
                for((j = 0; j < nr_colls_cond; ++j)) #parcurg coloanele cu conditii
                do
                        if [ "${row[${index_colls_with_cond[$j]}]}" != "${cond_val[$j]}" ]; then
                                ok="false"

                                #daca difera nu se vor efectua modificari asupra acestei linii
                        fi

                done

                declare -a updated_row


                if [ "$ok" == "true" ]; then #daca linia a intalnit toate conditiile

                        indez=(${index_colls_to_be_upd[@]}) #salvez toate indexurile coloanelor in alta matrice
                        index_upd=0; #variabila temporara de salvare a indexurilor
                        for ((k = 0; k < nr_colls; ++k))
                        do

                                if [ "$k" == "${indez[$index_upd]}" ]; then #daca pe coloana k corespunde o valoare ce trebuie modificata

                                        updated_row[k]="${upd_vals[$index_upd]}" #atasez valoarea corespunzatoare

                                        ((index_upd=index_upd+1)) #trec la urmatoarea valoare

                                else

                                        updated_row[k]="${row[$k]}" #daca valoarea de pe coloana k nu trebuie modificata copiez din linia originala
                                fi

                        done

                        rw="${row[@]}"
                        rwu="${updated_row[@]}"

                        ok_update=1
                fi


                for (( j = 0; j < nr_colls_tbu; ++j))
                        do


                                index="${index_colls_to_be_upd[$j]}"


                                if [[ "${datatypes[$index+1]}" == "int" ]]; then

                                        re='^[0-9]+$'
                                        if ! [[ "${upd_vals[$j]}" =~ $re ]] ; then
                                           echo -e ${RED}"Value '${upd_vals[$j]}' does not match 'int' datatype of col ${colls_to_be_upd[$j]}"${NC}
                                                ok_datatype=0;
                                                ok_update=0;
                                        return
                                        fi


                                fi
                        done

                if [ "${ok_update}" == "1" ]; then
                        sed -i "${i} s/${rw}/${rwu}/g" "${command[1]}" #inlocuiesc coloana de pe linia i
                        ok_afisare=1
                fi

        done

                if [ "${ok_afisare}" == "1" ]; then
                        echo -e "\e[3mDatabase updated successfully\e[0m"
                fi


        #echo "-----"
        #tail -n +2 "${command[1]}" #afisez fisierul modificat
        #echo "-----"

}


function SELECT_FROM()

{

touch copie.txt;

nrw=${#command[@]};

if [ "${command[1]}" == "*" -a "$nrw" == 4 ] #utilizatorul doreste sa selecteze toate coloanele(i.e. intregul tabel)
then
        tail -n +2 "${command[3]}" > copie.txt; #numele fisierului se afla pe pozitia a 3a din vectorul command
        awk '{print}' copie.txt | column -t;
fi


if [ "${command[1]}" != "*" -a "${command[nrw-2]}" == "FROM" ]
then

        n=$nrw-3;

        s="${command[1]}";
        if (( "$n"!= 1 ))
        then
                s+=',';
        fi

        for ((i=2;i<="$n";i+=1))
        do
                s+="${command[i]}";
                if (( i != "$n" ))
                then
                        s+=',';
                fi
        done

        tail -n +2 ${command[$nrw - 1]} > copie.txt;

        cat copie.txt | tr -s ' ' ',' > copie.csv;

        csvcut -c "$s" copie.csv > copie.txt ;

        column -t -s ',' copie.txt;

        rm copie.csv;

        s="";
fi

if [ "${command[nrw-4]}" == "WHERE" ]
then
        if [ "${command[1]}" == "*" ]
        then
                tail -n +2 "${command[3]}" > copie.txt;
                cat copie.txt | tr -s ' ' ',' > copie.csv;
                csvcut -c "${command[nrw-3]}" copie.csv > copie2.txt;

                if [ "${command[nrw-2]}" == "=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if [ $line != ${command[nrw-1]} -a $ok == 1 ]
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                if [ "${command[nrw-2]}" == "!=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if [ $line = ${command[nrw-1]} -a $ok == 1 ]
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                if [ "${command[nrw-2]}" == "<" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( $line >= ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                if [ "${command[nrw-2]}" == ">" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( $line <= ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                if [ "${command[nrw-2]}" == "<=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( $line > ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                if [ "${command[nrw-2]}" == ">=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( $line < ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.txt;
                                fi
                                ok=1;
                        done < copie2.txt
                        awk '{print}' copie.txt | column -t;
                fi

                rm copie.csv;
                rm copie2.txt;
        fi

        if [ "${command[1]}" != "*" ]
        then
                i=1;
                while [ "${command[i]}" != "FROM" ]
                do
                        s+="${command[i]}";
                        ((i=i+1))
                        if [ "${command[i]}" != "FROM" ]
                        then
                                s+=',';
                        fi
                done
                tail -n +2 ${command[i + 1]} > copie.txt;
                cat copie.txt | tr -s ' ' ',' > copie.csv;
                csvcut -c "${command[nrw-3]}" copie.csv > copie2.txt;

                if [ "${command[nrw-2]}" == "=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if [ $line != ${command[nrw-1]} -a $ok == 1 ]
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi

                if [ "${command[nrw-2]}" == "!=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if [ $line == ${command[nrw-1]} -a $ok == 1 ]
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi

                if [ "${command[nrw-2]}" == "<" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( ${line} >= ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi

                if [ "${command[nrw-2]}" == ">" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( ${line} <= ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi

                if [ "${command[nrw-2]}" == "<=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( ${line} > ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi

                if [ "${command[nrw-2]}" == ">=" ]
                then
                        ok=0;
                        while IFS= read -r line
                        do
                                if (( ${line} < ${command[nrw-1]} && $ok == 1 ))
                                then
                                        sed -i "/${line}/d" ./copie.csv;
                                fi
                                ok=1;
                        done < copie2.txt
                        csvcut -c "$s" copie.csv > copie.txt ;
                        column -t -s ',' copie.txt;
                fi
                rm copie.csv;
                rm copie2.txt;
                s="";

        fi
fi

rm copie.txt;

}
#----------------------------------------#



function INSERT(){

GREEN='\033[0;32m'


# verific daca exista fisierul in care urmeaza sa scriu
if test -f "${command[2]}"
then


# nr_col = numarul de coloane
nr_col="$(wc -w <<< "$(sed '2!d' "${command[2]}" )")"


# citesc in line prima linie din fisierul ${command[2]}
read -ra line < ${command[2]}


# line2 memoreaza numele coloanelor din fisier
line2=($(sed '2!d' "${command[2]}"))


# numar cate cuvinte sunt in comanda
nr_words=0
for txt in "${command[@]}"
{
        (( nr_words++ ))
}


# verificam daca avem VALUES in sintaxa functiei
if [ "${command[3+($nr_words-3)/2]}" == "VALUES" ]
then


index_vl=($nr_words-3)/2


# ok0 = 1 daca toate numele coloanelor exista in fisier
# ok0 = 0 daca cel putin o coloana introdusa nu exista
ok0=1
for(( j=0; j < $index_vl; j++))
{
    ok=1
    for(( i=0; i < $nr_col; i++))
    {
        if [ "${command[3+$j]}" == "${line2[$i]}" ]
        then
            ok=0
            indici[$j]=$i;
            break;
        fi
    }

    if [ $ok == 1 ]
    then
        echo -e "\e[31mNu exista coloana "${command[3+$j]}"\e[0m" #colorat rosu
            ok0=0
    fi
}


# daca minim un nume de coloana este gresit
if [ $ok0 == 0 ]
then
    echo Fisierul "${command[2]}" contine, in ordine, urmatoarele coloane:
    echo ${line2[@]}
else
# altfel continuta


# ok ramane 1 daca nu a fost nicio problema la introducerea datelor
# ok devine 0 daca trebuie reapelata functia
ok=1


for(( i=0; i < $index_vl; i++))
 {
    # daca pe pozitia i programul astepta un char, dar a primit un numar
    # => afisez un mesaj aferent + ok=0
  [[ "${line[indici[$i]]}" == "char" ]] && [[ "${command[$index_vl+4+$i]}" == ?(+|-)+([0-9]) ]] && echo -e "\e[31m"${command[$index_vl+4+$i]}" trebuia sa fie char\e[0m" && ok=0

    # acelasi lucru dar invers (astepta numar si a primit sir de caractere)
  [[ "${line[indici[$i]]}" == "int" ]] && [[ "${command[$index_vl+4+$i]}" != ?(+|-)+([0-9]) ]] && echo -e "\e[31m"${command[$index_vl+4+$i]}" trebuia sa fie numar\e[0m" && ok=0
 }


# daca ok a devenit 0 => sare peste partea
# in care introduce valorile in fisier
if [ $ok == 0 ]
then
    echo -e "\e[31mVa rog reapelati functia\e[0m"; # afisez cu rosu
else


# TOATE VERIFICARILE AU FOST FACUTE CU SUCCES
# urmeaza introducerea datelor in table

for(( i=0; i < $index_vl; i++ ))
{
    if [ "$i" == "0" ]
    then
        for(( j=0; j<indici[$i]; j++ ))
            {
                echo -ne "- " >> ${command[2]}
            }
    else
        for(( j=0; j<indici[$i]-indici[$i-1]-1; j++ ))
            {
                echo -ne "- " >> ${command[2]}
            }
    fi
    echo -ne "${command[$index_vl+4+$i]} " >> ${command[2]}
}


# daca indicele coloanei salvat pe ultima pozitie din indici[]
# este < numarul de coloane din tabel, inseamna ca mai trebuie
# completat cu spatii goale
if [[ $indici[$index_vl-1] < $nr_col-1 ]]
then
    for(( i=0; i<$nr_col-1-indici[$index_vl-1]; i++))
    {
        echo -ne "- " >> ${command[2]}
    }
fi


# trecem la urmatorul rand in fisier
echo "" >> ${command[2]}


echo -e ${GREEN}"\e[1mValoarea s-a introdus cu succes!\e[0m" # afisez verde italic


fi # if [ $ok == 0 ]
fi # if [ $ok0 == 0 ]


else # if [ "${command[3+($nr_words-3)/2]}" == "VALUES" ]
    echo -e "\e[31mEroare de sintaxa\e[0m"
    echo -e "\e[31mINSERT INTO table_name cloumn1 column2 ... VALUES value1 values2\e[0m"
fi


else # if test -f "${command[2]}"
    echo -e "\e[31mFisierul "${command[2]}" nu exista\e[0m" # afisez cu rosu
fi

}

function DROP(){


  if [ "${command[1]}" == "TABLE" ]
  then
    if test -f "${command[2]}";
    then
      rm "${command[2]}";
      else
          echo -n "Nu exista o tabela cu acest nume!";
      fi
  fi

  if [ "${command[1]}" == "DB" ]
  then
    if test -d "${command[2]}";
    then
      rm -r "${command[2]}";
      else
          echo -n "Nu exista o baza de date cu acest nume!";
      fi
  fi


}

function DBS(){
        ls -d -- */
}

function TABLES(){
        ls
}

function HELP(){

        #CREATE OPEN/CLOSE INSERT SELECT UPDATE DROP DBS TABLES QUIT HELP

        if [ "$1" == "CREATE" ]; then
                less /home/"$user"/CREATE
        fi

        if [ "$1" == "OPEN" ]; then
                less /home/"$user"/OPEN
        fi

        if [ "$1" == "CLOSE" ];then
                less /home/"$user"/CLOSE
        fi

        if [ "$1" == "INSERT" ]; then
                less /home/"$user"/INSERT
        fi

        if [ "$1" == "SELECT" ]; then
                less /home/"$user"/SELECT
        fi

        if [ "$1" == "UPDATE" ]; then
                less /home/"$user"/UPDATE
        fi

        if [ "$1" == "DROP" ]; then
                less /home/"$user"/DROP
        fi

        if [ "$1" == "DBS" ]; then
                less /home/"$user"/DBS
        fi

        if [ "$1" == "TABLES" ]; then
                less /home/"$user"/TABLES
        fi

        if [ "$1" == "QUIT" ]; then
                less /home/"$user"/QUIT
        fi

        if [ "$1" == "HELP" ]; then
                less /home/"$user"/HELP
        fi

        if [ "$1" == "" ]; then
                less /home/"$user"/HELP
        fi


}


while true
do
                if [ "${command[0]}" == "DBS" ]; then


                if [ "$db_open" == 1 ]; then

                        echo "DB already opened. Please close db and try again.";
                fi
                if  [ "$db_open" == "0" ];  then

                        DBS

                fi
        fi

        if [ "${command[0]}" == "TABLES" ]; then

                if [ "$db_open" == 1 ]; then
                        TABLES
                else
                        echo "Nu exista o baza de date deschisa"
                fi

        fi

        if [ "${command[0]}" == "CREATE" ]
        then

                CREATE

        fi

        if [ "${command[0]}" == "OPEN" ]
        then

                OPEN "${command[1]}"
                db_open=1;
        fi

        if [ "${command[0]}" == "CLOSE" ]
        then

                        CLOSE "${command[1]}"
                        db_open=0;

        fi

        if [ "${command[0]}" == "SELECT" ]
        then

                SELECT_FROM "$command"

        fi

        if [ "${command[0]}" == "UPDATE" ]
        then

                UPDATE "$command"

        fi

        if [ "${command[0]}" == "DROP" ]
        then

                DROP

        fi

        if [ "${command[0]}" == "INSERT" ]
        then

                        INSERT "$command"

        fi

        if [ "${command[0]}" == "QUIT" ]
        then
                        echo "Are you sure you want to quit?(Y/N)"
                        read answer
                        if [ "$answer" == "Y" ];
                        then
                        exit 0

                        else
                                if [ "$answer" == "N" ];
                                then
                                echo "Ok"
                                fi
                        fi


        fi

        if [ "${command[0]}" == "HELP" ]; then

                HELP "${command[1]}"

        fi

        echo  -ne "$user$>";
        read -a command;

done