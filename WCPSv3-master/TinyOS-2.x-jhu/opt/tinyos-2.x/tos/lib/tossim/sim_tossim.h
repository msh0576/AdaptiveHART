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
 * Implementation of all of the basic TOSSIM primitives and utility
 * functions.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id$

#ifndef SIM_TOSSIM_H_INCLUDED
#define SIM_TOSSIM_H_INCLUDED

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef long long int sim_time_t;

void sim_init();
void sim_start();
void sim_end();

void sim_random_seed(int seed);
int sim_random();

sim_time_t sim_time();
void sim_set_time(sim_time_t time);
sim_time_t sim_ticks_per_sec();

unsigned long sim_node();
void sim_set_node(unsigned long node);

int sim_print_time(char* buf, int bufLen, sim_time_t time);
int sim_print_now(char* buf, int bufLen);
char* sim_time_string();

void sim_add_channel(char* channel, FILE* file);// I think this is about output channel for debugging of tossim? added by Bo
bool sim_remove_channel(char* channel, FILE* file);// This one too? added by Bo
//bool sim_run_next_event();

int sim_run_next_event();

//added by sihoon
void sim_send_VirtualSchedule(int nodeid, int TxOffset, int dummy1, int dummy2 );
int* sim_get_VirtualSchedule();
void sim_send_TaskPeriods(int Task1_T, int Task2_T, int Task3_T, int Task4_T);
int* sim_get_TaskPeriods();
void sim_send_NumTx(int Task1_Tx, int Task2_Tx, int Task3_Tx, int Task4_Tx);
int* sim_get_TaskTx();

#ifdef __cplusplus
}
#endif

#endif // SIM_TOSSIM_H_INCLUDED