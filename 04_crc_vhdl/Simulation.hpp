#ifndef SIMULATION_H // se il simbolo SIMULATION_H non è definito
#define SIMULATION_H // definisci il simbolo SIMULATION_H

using namespace std;

class Simulation
{
public:
    // Costruttore e distruttore
    Simulation(unsigned int = 0);
    ~Simulation();

    // Metodi pubblici
    void generateCommands(string iFName);
    void generateReference_CRCsingle(string iFName, string ref_FName);
    void generateReference_CRClong(string iFName, string ref_FName);

    void run(string fileCompilazione);
    unsigned int report(string risultati_tb, string risultati_ref);

private:
    unsigned int correct;
};

#endif
