// PerfMon.xs
//       +==========================================================+
//       |                                                          |
//       |                        PerfMon.xs                        |
//       |                     ---------------                      |
//       |                                                          |
//       | Copyright (c) 2004 Glen Small. All rights reserved. 	    |
//       |   This program is free software; you can redistribute    |
//       | it and/or modify it under the same terms as Perl itself. |
//       |                                                          |
//       +==========================================================+
//
//
//	Use under GNU General Public License or Larry Wall's "Artistic License"
//
//Check the README.TXT file that comes with this package for details about
//	it's history.
//

#define WIN32_LEAN_AND_MEAN

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "windows.h"
#include "PDH.h"
#include "PDHMSG.h"


MODULE = Win32::PerfMon		PACKAGE = Win32::PerfMon

void
open_query()

	PREINIT:

		PDH_STATUS stat;
		HQUERY	hQwy;
		DWORD dwGlen;

	PPCODE:

		dwGlen = 1;

		stat = PdhOpenQuery(NULL, dwGlen, &hQwy);


		if(stat != ERROR_SUCCESS)
		{
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		else
		{
			XPUSHs(sv_2mortal(newSViv((long)hQwy)));
		}




void
CleanUp(objQuery)
	SV* objQuery

	PREINIT:

		PDH_STATUS stat;
		HQUERY	pObj;

	PPCODE:

		pObj = (HQUERY)SvIV(objQuery);

		stat = PdhCloseQuery(pObj);


void
add_counter(BoxName, ObjectName, CounterName, InstanceName, InstanceNumber, pQwy, pError)
	SV* BoxName
	SV* ObjectName
	SV* CounterName
	SV* InstanceName
	SV* InstanceNumber
	SV* pQwy
	SV* pError;

	PREINIT:

		PDH_COUNTER_PATH_ELEMENTS	GStruct;
		DWORD dwSize;
		DWORD dwGlen;
		HCOUNTER cnt;
		HQUERY hQwy;
		char str[256];
		PDH_STATUS	stat;
		STRLEN len1;
		STRLEN len2;
		STRLEN len3;
		STRLEN BoxNameLen;
		DWORD TheInstance;

	PPCODE:

		hQwy = (HQUERY)SvIV(pQwy);

		dwGlen = 1;
		dwSize = 256;

		len1 = sv_len(ObjectName);
		len2 = sv_len(CounterName);
		BoxNameLen = sv_len(BoxName);

		TheInstance = SvUV(InstanceNumber);

		if(TheInstance == -1)
		{
			TheInstance = 0;
		}

		if(SvNIOK(InstanceName))
		{
			GStruct.szInstanceName = NULL;
		}
		else
		{
			len3 = sv_len(InstanceName);
			GStruct.szInstanceName = SvPV(InstanceName, len3);
		}

		GStruct.szObjectName = SvPV(ObjectName, len1);
		GStruct.szCounterName = SvPV(CounterName, len2);
		GStruct.szMachineName = SvPV(BoxName, BoxNameLen);
		GStruct.szParentInstance = NULL;
		GStruct.dwInstanceIndex = TheInstance;

		stat = PdhMakeCounterPath(&GStruct, (char*)str, &dwSize, NULL);



		if(stat != ERROR_SUCCESS)
		{
			sv_setpv(pError, "Failed to make the counter path - either the object, counter, or instance isn't valid");
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		else
		{

			stat = PdhAddCounter(hQwy, (LPTSTR)str, dwGlen, &cnt);

			switch(stat)
			{
				case ERROR_SUCCESS:

					XPUSHs(sv_2mortal(newSViv((long)cnt)));

					break;

				case PDH_CSTATUS_BAD_COUNTERNAME:

					sv_setpv(pError, "The counter name path string could not be parsed or interpreted.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTER:

					sv_setpv(pError, "The specified counter was not found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTERNAME:

					sv_setpv(pError, "An empty counter name path string was passed in.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_MACHINE:

					sv_setpv(pError, "A computer entry could not be created.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_OBJECT:

					sv_setpv(pError, "The specified object could not be found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_FUNCTION_NOT_FOUND:

					sv_setpv(pError, "The calculation function for this counter could not be determined.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_ARGUMENT:

					sv_setpv(pError, "One or more arguments are invalid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_HANDLE:

					sv_setpv(pError, "The query handle is not valid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_MEMORY_ALLOCATION_FAILURE:

					sv_setpv(pError, "A memory buffer could not be allocated.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				default:

					sv_setpv(pError, "Failed to add the counter - don't know why");
					XPUSHs(sv_2mortal(newSViv(-1)));
			}
		}





void
collect_data(pQwy, pError)
	SV* pQwy
	SV* pError

	PREINIT:

		HQUERY hQwy;
		PDH_STATUS stat;

	PPCODE:


		hQwy = (HQUERY)SvIV(pQwy);

		stat = PdhCollectQueryData(hQwy);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSViv(0)));

				break;

			case PDH_INVALID_HANDLE:

				sv_setpv(pError, "The query handle is not valid.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_NO_DATA:

				sv_setpv(pError, "The query does not currently have any counters.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "Collect Data Failed - I don't know why");
				XPUSHs(sv_2mortal(newSViv(-1)));

		}

void
collect_counter_value(pQwy, pCounter, pError)
	SV* pQwy
	SV* pCounter
	SV* pError

	PREINIT:

		HQUERY hQwy;
		HCOUNTER hCnt;
		PDH_STATUS stat;
		PDH_FMT_COUNTERVALUE val;
		DWORD dwType;

	PPCODE:

		hQwy = (HQUERY)SvIV(pQwy);
		hCnt = (HCOUNTER)SvIV(pCounter);

		stat = PdhGetFormattedCounterValue(hCnt, PDH_FMT_LONG | PDH_FMT_NOSCALE , &dwType, &val);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSViv(val.longValue)));

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "An argument is not correct or is incorrectly formatted.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_DATA:

				sv_setpv(pError, "The specified counter does not contain valid data or a successful status code.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_HANDLE:

				sv_setpv(pError, "The counter handle is not valid.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "Failed to get the counter value - I don't know why.");
				XPUSHs(sv_2mortal(newSViv(-1)));

		}


void
list_objects(pBox, pError)
	SV*	pBox
	SV* pError

	PREINIT:

		DWORD dwSize;
		PDH_STATUS stat;
		char* szBuffer;
		char* szBox;
		char* c;
		STRLEN len;
		int index;

	PPCODE:

		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		stat = PdhEnumObjects(NULL, szBox, NULL, &dwSize, PERF_DETAIL_EXPERT, 0);

		Newz(0, szBuffer, (int)dwSize, char);

		stat = PdhEnumObjects(NULL, szBox, szBuffer, &dwSize, PERF_DETAIL_EXPERT, 0);

		c = szBuffer;

		for(index=0; index<(int)dwSize; index++)
		{
			if(*c == 0x00)
			{
				*c = '|';
			}

			c++;
		}

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSVpv(szBuffer, 0)));

				break;

			case PDH_MORE_DATA:

				printf("There are more entries available to return than there is room in the buffer\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INSUFFICIENT_BUFFER:

				sv_setpv(pError, "The buffer provided is not large enough to contain any data.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "A required argument is invalid or a reserved argument is not NULL.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "I have no idea what went wrong\n");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

		Safefree(szBuffer);

void
connect_to_box(pBox, pError)
	SV* pBox
	SV* pError

	PREINIT:

		PDH_STATUS stat;
		char* szBox;
		STRLEN len;

	PPCODE:

		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		stat = PdhConnectMachine(szBox);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSViv(0)));

				break;

			case PDH_CSTATUS_NO_MACHINE:

				sv_setpv(pError, "Unable to connect to the specified machine");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_MEMORY_ALLOCATION_FAILURE:

				sv_setpv(pError, "Unable to allocate a dynamic memory block due to too many applications running on the system or an insufficient memory paging file.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "ERROR: Don't really know what happened though !");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

void
explain_counter(pCounter, pError)
	SV* pCounter
	SV* pError

	PREINIT:

		PDH_COUNTER_INFO* cntInfo;
		HCOUNTER cnt;
		PDH_STATUS	stat;
		DWORD dwSize;

	PPCODE:

		cnt = (HCOUNTER)SvIV(pCounter);
		cntInfo = NULL;
		dwSize = 0;

		stat = PdhGetCounterInfo(cnt, 1, &dwSize, cntInfo);

		New(0, cntInfo, (int)dwSize, PDH_COUNTER_INFO);

		cntInfo->dwLength = dwSize;

		stat = PdhGetCounterInfo(cnt, 1, &dwSize, cntInfo);

		if(stat ==  ERROR_SUCCESS)
		{
			XPUSHs(sv_2mortal(newSVpv(cntInfo->szExplainText, 0)));
		}
		else
		{
			sv_setpv(pError, "Failed to get the explain text for this counter");
			XPUSHs(sv_2mortal(newSViv(-1)));
		}


		Safefree(cntInfo);


void
remove_counter(pCounter, pError)
	SV* pCounter
	SV* pError

	PREINIT:

		HCOUNTER cnt;
		PDH_STATUS stat;

	PPCODE:

		cnt = (HCOUNTER)SvIV(pCounter);

		stat = PdhRemoveCounter(cnt);

		if(stat == PDH_INVALID_HANDLE)
		{
			sv_setpv(pError, "The query handle is not valid.");
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		else
		{
			XPUSHs(sv_2mortal(newSViv(0)));
		}


void
list_counters(pBox, pObject, pError)
	SV*	pBox
	SV* pObject
	SV* pError

	PREINIT:

		DWORD dwSize;
		DWORD dwSize1;
		PDH_STATUS stat;
		char* szBuffer;
		char* szBuffer2;
		char* szBox;
		char* szObject;
		char* c;
		STRLEN len;
		STRLEN len2;
		int index;

	PPCODE:

		dwSize = 0;
		dwSize1 = 0;
		szBuffer = NULL;
		szBuffer2 = NULL;
		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		len2 = sv_len(pObject);
		szObject = SvPV(pObject, len2);

		stat = PdhEnumObjects(NULL, szBox, NULL, &dwSize, PERF_DETAIL_EXPERT, 1);

		dwSize = 0;

		stat = PdhEnumObjectItems(NULL, szBox, szObject, szBuffer, &dwSize, szBuffer2, &dwSize1, PERF_DETAIL_EXPERT, 0);

		dwSize += 5;

		Newz(0, szBuffer, (int)dwSize, char);

		stat = PdhEnumObjectItems(NULL, szBox, szObject, szBuffer, &dwSize, szBuffer2, &dwSize1, PERF_DETAIL_EXPERT, 0);

		c = szBuffer;

		for(index=0; index<(int)dwSize; index++)
		{
			if(*c == 0x00)
			{
				*c = '|';
			}

			c++;
		}

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSVpv(szBuffer, 0)));

				break;

			case PDH_MORE_DATA:

				printf("There are more entries available to return than there is room in the buffer\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_MEMORY_ALLOCATION_FAILURE:

				sv_setpv(pError, "A required temporary buffer could not be allocated.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "A required argument is invalid or a reserved argument is not NULL.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_CSTATUS_NO_MACHINE:

				sv_setpv(pError, "The specified computer is offline or unavailable.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_CSTATUS_NO_OBJECT:

				sv_setpv(pError, "The specified object could not be found on the specified computer.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "I have no idea what went wrong\n");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

		Safefree(szBuffer);

void
list_instances(pBox, pObject, pError)
	SV*	pBox
	SV* pObject
	SV* pError

	PREINIT:

		DWORD dwSize;
		DWORD dwSize1;
		PDH_STATUS stat;
		char* szBuffer;
		char* szBuffer2;
		char* szBox;
		char* szObject;
		char* c;
		STRLEN len;
		STRLEN len2;
		int index;

	PPCODE:

		dwSize = 0;
		dwSize1 = 0;
		szBuffer = NULL;
		szBuffer2 = NULL;
		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		len2 = sv_len(pObject);
		szObject = SvPV(pObject, len2);

		stat = PdhEnumObjects(NULL, szBox, NULL, &dwSize, PERF_DETAIL_EXPERT, 1);

		dwSize = 0;

		stat = PdhEnumObjectItems(NULL, szBox, szObject, szBuffer, &dwSize, szBuffer2, &dwSize1, PERF_DETAIL_EXPERT, 0);

		dwSize1 += 5;

		Newz(0, szBuffer2, (int)dwSize1, char);

		stat = PdhEnumObjectItems(NULL, szBox, szObject, szBuffer, &dwSize, szBuffer2, &dwSize1, PERF_DETAIL_EXPERT, 0);

		c = szBuffer2;

		for(index=0; index<(int)dwSize1; index++)
		{
			if(*c == 0x00)
			{
				*c = '|';
			}

			c++;
		}

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSVpv(szBuffer2, 0)));

				break;

			case PDH_MORE_DATA:

				printf("There are more entries available to return than there is room in the buffer\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_MEMORY_ALLOCATION_FAILURE:

				sv_setpv(pError, "A required temporary buffer could not be allocated.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "A required argument is invalid or a reserved argument is not NULL.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_CSTATUS_NO_MACHINE:

				sv_setpv(pError, "The specified computer is offline or unavailable.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_CSTATUS_NO_OBJECT:

				sv_setpv(pError, "The specified object could not be found on the specified computer.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "I have no idea what went wrong\n");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

		Safefree(szBuffer2);
