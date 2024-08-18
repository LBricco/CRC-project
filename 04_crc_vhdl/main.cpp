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

int main(int argc, char **argv)
{

    int ret = 0;          // variabile per il return
    Simulation Simulator; // oggetto della classe Simulation per l'automatizzazione della simulazione
    Tools CRC_calculator;

    /**********************************************************************************/
    /*        Inizializzazione degli oggetti necessari alla gestione dei file         */
    /**********************************************************************************/

    string tbFileName = "tb_crc_complete.vhd"; // testbench
    string compileFileName = "compile.do";     // file con le info per la simulazione
    string input_singleFileName = "input_commands_single.txt";
    string input_longFileName = "input_commands_long.txt";
    string ref_singleFileName = "ref_single.txt";
    string ref_longFileName = "ref_long.txt";
    string tb_singleFileName = "output_results_single.txt";
    string tb_longFileName = "output_results_long.txt";

    // check esistenza testbench
    if (!filesystem::exists(tbFileName))
    {
        cerr << "Errore! La testbench " << tbFileName << " non esiste." << endl;
        ret = 1;
    }

    // check esistenza file per la compilazione
    if (!filesystem::exists(compileFileName))
    {
        cerr << "Errore! Il file per la compilazione " << compileFileName << " non esiste." << endl;
        ret = 1;
    }

    /**********************************************************************************/
    /*                  Calcolo del CRC di singole parole da 16 bit                   */
    /**********************************************************************************/

    // generazione file di scrittura
    Simulator.generateCommands(input_singleFileName);
    // generazione file di riferimento
    Simulator.generateReference_CRCsingle(input_singleFileName, ref_singleFileName);

    /**********************************************************************************/
    /*                       Calcolo del CRC di messaggi lunghi                       */
    /**********************************************************************************/

    // generazione file di scrittura
    Simulator.generateCommands(input_longFileName);
    // generazione file di riferimento
    Simulator.generateReference_CRClong(input_longFileName, ref_longFileName);

    // simulazione automatizzata
    cout << endl
         << "*********************************************************************"
         << endl;
    cout << "Inizio Simulazione Modelsim" << endl;
    Simulator.run(compileFileName);
    cout << endl
         << "Fine Simulazione Modelsim" << endl;
    cout << "*********************************************************************"
         << endl
         << endl;

    // controllo risultati
    cout << "Calcolo CRC di singole parole di 16 bit:" << endl;
    int single_OK = Simulator.report(ref_singleFileName, tb_singleFileName);
    if (single_OK == 1)
    {
        cout << "I risultati della simulazione corrispondono a quelli generati con lo script C++." << endl
             << endl;
    }
    else
    {
        cout << endl
             << "Non tutti i risultati della simulazione corrispondono a quelli generati con lo script C++." << endl
             << endl;
    }

    cout << endl
         << "Calcolo CRC di messaggi arbitrarimente lunghi (fino a 100 parole):" << endl;
    int long_OK = Simulator.report(ref_longFileName, tb_longFileName);
    if (long_OK == 1)
    {
        cout << "I risultati della simulazione corrispondono a quelli generati con lo script C++." << endl
             << endl;
    }
    else
    {
        cout << endl
             << "Non tutti i risultati della simulazione corrispondono a quelli generati con lo script C++." << endl
             << endl;
    }

    if (single_OK && long_OK)
    {
        cout << "Il calcolatore di CRC-16-CCITT/XMODEM funziona correttamente! :)" << endl;
    }
    else
    {
        cout << "Il calcolatore di CRC-16-CCITT/XMODEM non funziona correttamente. :(" << endl;
    }
    cout << endl;
    return ret; // punto di uscita dal programma
}