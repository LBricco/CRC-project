PREFIX=
ARMILINK=
CC=g++

main: main.o Tools.o Converter.o Simulation.o
	$(CC) -o main main.o Tools.o Converter.o Simulation.o

main.o: main.cpp Tools.hpp Converter.hpp Simulation.hpp
	$(CC) -c main.cpp

Tools.o: Tools.cpp Tools.hpp Converter.hpp
	$(CC) -c Tools.cpp

Converter.o: Converter.cpp Converter.hpp
	$(CC) -c Converter.cpp

Simulation.o: Simulation.cpp Simulation.hpp Tools.hpp Converter.hpp
	$(CC) -c Simulation.cpp