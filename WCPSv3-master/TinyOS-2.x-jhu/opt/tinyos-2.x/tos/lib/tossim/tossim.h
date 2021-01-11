/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Declaration of C++ objects representing TOSSIM abstractions.
 * Used to generate Python objects.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id$

#ifndef TOSSIM_H_INCLUDED
#define TOSSIM_H_INCLUDED

//#include <stdint.h>
#include <memory.h>
#include <tos.h>
#include <mac.h>
#include <radio.h>
#include <packet.h>
#include <hashtable.h>

typedef struct variable_string {
  char* type;
  char* ptr;
  int len;
  int isArray;
} variable_string_t;

typedef struct nesc_app {
  int numVariables;
  char** variableNames;
  char** variableTypes;
  int* variableArray;
} nesc_app_t;

class Variable {
 public:
  Variable(char* name, char* format, int array, int mote);
  ~Variable();
  variable_string_t getData();

 private:
  char* name;
  char* realName;
  char* format;
  int mote;
  void* ptr;
  char* data;
  size_t len;
  int isArray;
  variable_string_t str;
};

class Mote {
 public:
  Mote(nesc_app_t* app);
  ~Mote();

  unsigned long id();

  long long int euid();
  void setEuid(long long int id);

  long long int bootTime();
  void bootAtTime(long long int time);

  bool isOn();
  void turnOff();
  void turnOn();

  //added by Bo
  bool isIdle();
  void enableIdle();
  void disableIdle();

  void setID(unsigned long id);

  void addNoiseTraceReading(int val, int channel);
  void createNoiseModel(int channel);
  int generateNoise(int when);

  Variable* getVariable(char* name);

 private:
  unsigned long nodeID;
  nesc_app_t* app;
  struct hashtable* varTable;
};

class Tossim {
 public:
  Tossim(nesc_app_t* app);
  ~Tossim();

  void init();

  long long int time();
  long long int ticksPerSecond();
  char* timeStr();
  void setTime(long long int time);

  Mote* currentNode();
  Mote* getNode(unsigned long nodeID);
  void setCurrentNode(unsigned long nodeID);

  void addChannel(char* channel, FILE* file);
  bool removeChannel(char* channel, FILE* file);
  void randomSeed(int seed);

  //added by sihoon
  void sendVirtualSchedule(int nodeid, int TxOffset, int dummy1, int dummy2 );
  void sendTaskPeriods(int Task1_T, int Task2_T, int Task3_T, int Task4_T);
  void sendNumTx(int Task1_Tx, int Task2_Tx, int Task3_Tx, int Task4_Tx);
  //bool runNextEvent();
  //commented out and added a version below by Bo

  int runNextEvent();

  MAC* mac();
  Radio* radio();
  Packet* newPacket();

 private:
  char timeBuf[256];
  nesc_app_t* app;
  Mote** motes;
};



#endif // TOSSIM_H_INCLUDED