#include <iostream>
#include <fstream>    // per file processing
#include <sstream>    // per trattare le stringhe come stream di dati
#include <filesystem> // per verificare l'esistenza dei file
#include <cstdlib>    // per usare comandi shell
#include <string>     // per manipolazione stringhe
#include <cstring>    // per manipolazione stringhe C-like
#include <vector>     // per manipolazione vettori
#include <cmath>      // per funzioni matematiche
#include <iomanip>    // per formattazione I/O

#include "Tools.hpp"
#include "Converter.hpp"
#include "Simulation.hpp"

using namespace std;

// Costruttore
Simulation::Simulation(unsigned int c)
    : correct{c} {}

// Distruttore
Simulation::~Simulation() {}

// Genero file con i comandi per lo slave SPI
// @param iFName = nome file contenente comandi di interazione con l'interfaccia a registri
// @param ref_FName = nome file contenente i dati generati (per confronto con i risultati di Modelsim)
void Simulation::generateCommands(string iFName)
{
    Converter C;

    // check esistenza file (se non esistono li creo con una chiamata a system)
    if (!filesystem::exists(iFName))
        system(("touch " + iFName).c_str());

    // apro il file di input
    ofstream input_oF(iFName);

    // scrivo i comandi di scrittura e lettura generando casualmente 100 parole di 16 bit di cui calcolare il CRC
    if (input_oF) // se l'apertura è andata a buon fine
    {
        for (int word = 0; word < 100; word++)
        {
            int din = rand() % 65536; // dato da scrivere

            // scrivo comando di scrittura di DIN nell'indirizzo 0 (Data In Register)
            C.intToBin(to_string(32), 8, input_oF);   // comando di scrittura
            C.intToBin(to_string(0), 8, input_oF);    // indirizzo
            C.intToBin(to_string(din), 16, input_oF); // dato
            input_oF << endl;
        }

        // chiudo il file di input
        input_oF.close();
    }
}

// Calcolo il CRC di singole parole
void Simulation::generateReference_CRCsingle(string iFName, string ref_FName)
{
    // apro il file di input in lettura e il file dei CRC di riferimento in scrittura
    ifstream input_iF(iFName);
    ofstream ref_F(ref_FName);
    string line;

    Tools CRC_calculator;

    // imposto parametri per calcolo CRC-16-CCITT XMODEM
    // generatore = x^16 + x^12 + x^5 + 1, LFSR inizializzato a 0
    CRC_calculator.set_crc("10001000000100001", 16, 0);

    if (input_iF && ref_F)
    {
        while (getline(input_iF, line))
        {
            string message = line.substr(16, 16); // nuovo messaggio
            CRC_calculator.calc_crc(message, ref_F);
        }
    }

    // chiudo i file
    input_iF.close();
    ref_F.close();
}

void Simulation::generateReference_CRClong(string iFName, string ref_FName)
{
    // apro il file di input in lettura e il file dei CRC di riferimento in scrittura
    ifstream input_iF(iFName);
    ofstream ref_F(ref_FName);
    string line;

    Tools CRC_calculator;

    // imposto parametri per calcolo CRC-16-CCITT XMODEM
    // generatore = x^16 + x^12 + x^5 + 1, LFSR inizializzato a 0
    CRC_calculator.set_crc("10001000000100001", 16, 0);
    string message;
    if (input_iF && ref_F)
    {
        while (getline(input_iF, line))
        {
            message += line.substr(16, 16); // aggiungo nuova parola
            CRC_calculator.calc_crc(message, ref_F);
        }
    }

    // chiudo i file
    input_iF.close();
    ref_F.close();
}

// Esecuzione simulazione mediante chiamata a system
void Simulation::run(string fileCompilazione)
{
    system(("vsim -c -do " + fileCompilazione).c_str()); // lancio la simulazione
}

// Controlla la correttezza dei risultati
unsigned int Simulation::report(string risultati_tb, string risultati_ref)
{
    string line_tb, line_ref; // righe dei due file
    int cnt_lines_tb = 0;     // contatore di riga del file generato dalla tb
    int cnt_lines_ref = 0;    // contatore di riga del file di riferimento
    int tot_correct = 0;      // numero totale di righe corrette all'interno del file generato dalla tb

    // apro i file in lettura
    ifstream tbF(risultati_tb);
    ifstream ref_F(risultati_ref);

    while (tbF.good() && ref_F.good())
    {
        // estraggo una riga da ognuno dei due file
        if (getline(tbF, line_tb) && getline(ref_F, line_ref))
        {
            // se i risultati della tb e del file di riferimento sono uguali incremento il contatore di righe corrette
            if (line_tb == line_ref)
            {
                tot_correct++;
            }
            // se i risultati sono diversi, esco dal ciclo (non ho più bisogno di controllare le righe restanti)
            else
            {
                cout << "Errore con il messaggio inviato alla riga " << cnt_lines_tb << endl;
                break;
            }

            // incremento i contatori di riga
            cnt_lines_tb++;
            cnt_lines_ref++;
        }
    }

    // chiudo i file
    tbF.close();
    ref_F.close();

    // stabilisco il valore del flag che mi dice se la simulazione è andata a buon fine
    if ((cnt_lines_tb == cnt_lines_ref) && (tot_correct == cnt_lines_ref))
        correct = 1;
    else
        correct = 0;

    return correct;
}
