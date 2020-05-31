new Iterator:Streets<MAX_STREETS>;

enum sokak
{
	sokakID,
	sokakIsim[32],
	Float:sokakRange,
	Float:sokakPos[3]
};

new Sokak[MAX_STREETS][sokak];

public OnGameModeInit()
{
	LoadStreets();
	return 1;
}

public OnGameModeExit()
{
	foreach(new i : Streets)
	{
		UpdateStreets(i);
	}
	return 1;
}

CMD:asokak(playerid, params[])
{
	if(oyuncu[playerid][pAdmin] < 5) return yetkisiz(playerid);
	Dialog_Show(playerid, DIALOG_ASOKAK, DIALOG_STYLE_LIST, "Admin - Sokak Menüsü", "Sokak Oluştur\nSokak Sil\nSokak Adı Öğren", "seç", "Iptal");
	return 1;
}

CMD:konum(playerid, params[])
{
	new text[128];
	new id = GetNearestStreet(playerid);
	if(id != -1)
	{
		format(text, sizeof(text), "Şu anda %s adlı sokağın içerisindesin.", GetStreetName(id));
		SendClientMessage(playerid, COLOR_GA, text);
	}
	return 1;
}

Dialog:DIALOG_ASOKAK(playerid, response, listitem, inputtext[])
{

	// 0 oluştur, 1 sil, 2 ad öğren

	if(!response) return 0;

	switch(listitem)
	{
		case 0:
		{
			Dialog_Show(playerid, DIALOG_ASOKAKOLUSTUR1, DIALOG_STYLE_INPUT, "Sokak Oluşturucu - Aşama #1", "Lütfen sokağa vereceğiniz ismi girin:", "Devam", "Iptal");
			SetPVarInt(playerid, "sokakolusturasama", 1);
		}
		case 1:
		{
			Dialog_Show(playerid, DIALOG_ASOKAKSIL, DIALOG_STYLE_INPUT, "Sokak Silici", "Lütfen silmek istediğiniz sokağın ID'sini girin:", "Sil", "Iptal");
		}
		case 2:
		{
			Dialog_Show(playerid, DIALOG_ASOKAKAD, DIALOG_STYLE_INPUT, "Sokak Ad Getirici", "Lütfen adını öğrenmek istediğiniz sokağın ID'sini girin:", "Öğren", "Iptal");
		}
	}

	return 1;
}

Dialog:DIALOG_ASOKAKOLUSTUR1(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		SetPVarInt(playerid, "sokakolusturasama", 0);
		return 0;
	}

	GetPlayerPos(playerid, oyuncu[playerid][pPos][0], oyuncu[playerid][pPos][1], oyuncu[playerid][pPos][2]);

	new id = Iter_Free(Streets);

	SetPVarInt(playerid, "sokakolusturid", id);
	SetPVarString(playerid, "sokakolusturisim", inputtext);

	SetPVarFloat(playerid, "sokakolusturx", oyuncu[playerid][pPos][0]);
	SetPVarFloat(playerid, "sokakolustury", oyuncu[playerid][pPos][1]);
	SetPVarFloat(playerid, "sokakolusturz", oyuncu[playerid][pPos][2]);

	Dialog_Show(playerid, DIALOG_ASOKAKOLUSTUR2, DIALOG_STYLE_INPUT, "Sokak Oluşturucu - Aşama #2", "Lütfen sokağın hissedileceği mesafeyi girin: (float, range)", "Devam", "Iptal");
	return 1;
}

Dialog:DIALOG_ASOKAKOLUSTUR2(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		SetPVarInt(playerid, "sokakolusturasama", 0);
		SetPVarInt(playerid, "sokakolusturid", -1);
		SetPVarString(playerid, "sokakolusturisim", "BOŞ");
		SetPVarFloat(playerid, "sokakolusturx", 0.0);
		SetPVarFloat(playerid, "sokakolustury", 0.0);
		SetPVarFloat(playerid, "sokakolusturz", 0.0);
		return 0;
	}

	new 
		query[256],
		text[128],
		id = GetPVarInt(playerid, "sokakolusturid"),
		sokakisim[32],
		Float:x = GetPVarFloat(playerid, "sokakolusturx"),
		Float:y = GetPVarFloat(playerid, "sokakolustury"),
		Float:z = GetPVarFloat(playerid, "sokakolusturz"),
		Float:range = floatstr(inputtext)
	;

	GetPVarString(playerid, "sokakolusturisim", sokakisim, sizeof(sokakisim));

 	format(Sokak[id][sokakIsim], sizeof(sokakisim), sokakisim);

 	Sokak[id][sokakRange] = range;
 	Sokak[id][sokakPos][0] = x;
 	Sokak[id][sokakPos][1] = y;
 	Sokak[id][sokakPos][2] = z;

 	mysql_format(sqlC, query, sizeof(query), "INSERT INTO streets(sokakIsim, sokakrange, sokakx, sokaky, sokakz) VALUES('%s', '%f', '%.4f', '%.4f', '%.4f')",
 	Sokak[id][sokakIsim],
 	Sokak[id][sokakRange],
 	Sokak[id][sokakPos][0],
 	Sokak[id][sokakPos][1],
 	Sokak[id][sokakPos][2]
 	);
 	mysql_query(sqlC, query);

 	Sokak[id][sokakID] = cache_insert_id();
 	Iter_Add(Streets, id);

 	format(text, sizeof(text), "Başarıyla %i ID'li sokağı oluşturdun. Sokağın adı: %s", id, Sokak[id][sokakIsim]);
 	SendClientMessage(playerid, COLOR_GA, text);

	return 1;
}

Dialog:DIALOG_ASOKAKSIL(playerid, response, listitem, inputtext[])
{
	if(!response) return 0;

	new id = strval(inputtext), query[256], text[128];

	format(text, sizeof(text), "Başarıyla %i ID'li sokağı sildin.", id);
	SendClientMessage(playerid, COLOR_AWARN, text);

	mysql_format(sqlC, query, sizeof(query), "DELETE FROM streets WHERE sokakID = '%d'", Sokak[id][sokakID]);
	mysql_query(sqlC, query);

	format(Sokak[id][sokakIsim], 32, "BOŞ");
	Sokak[id][sokakID] = -1;
	Sokak[id][sokakRange] = 0.0;
	Sokak[id][sokakPos][0] = 0.0;
	Sokak[id][sokakPos][1] = 0.0;
	Sokak[id][sokakPos][2] = 0.0;

	Iter_Remove(Streets, id);
	return 1;
}

Dialog:DIALOG_ASOKAKAD(playerid, response, listitem, inputtext[])
{
	if(!response) return 0;

	new id = strval(inputtext), text[128];

	format(text, sizeof(text), "Sokağın adı: '%s'.", GetStreetName(id));
	SendClientMessage(playerid, COLOR_ORANGE, text);
	
	return 1;
}

LoadStreets()
{
	new query[256], rows, Cache:street_cache;
	mysql_format(sqlC, query, sizeof(query), "SELECT * FROM streets");
	street_cache = mysql_query(sqlC, query);
	cache_get_row_count(rows);
	if(rows)
	{
		for(new i; i < cache_num_rows(); i++)
		{
			cache_get_value_int(i, "sokakid", Sokak[i][sokakID]);
			cache_get_value_name(i, "sokakisim", Sokak[i][sokakIsim], 32);
			cache_get_value_float(i, "sokakrange", Sokak[i][sokakRange]);
			cache_get_value_float(i, "sokakx", Sokak[i][sokakPos][0]);
			cache_get_value_float(i, "sokaky", Sokak[i][sokakPos][1]);
			cache_get_value_float(i, "sokakz", Sokak[i][sokakPos][2]);
			printf("%i ID'li sokak yüklendi. Sokak: %s - Range: %f", Sokak[i][sokakID], Sokak[i][sokakIsim], Sokak[i][sokakRange]);
			Iter_Add(Streets, i);
		}
		printf("%i sokak yüklendi.", cache_num_rows());
	}
	cache_delete(street_cache);
	return true;
}

UpdateStreets(i)
{
	new query[512];
	mysql_format(sqlC, query, sizeof(query), "UPDATE streets SET sokakIsim = '%s', sokakx = '%.4f', sokaky = '%.4f', sokakz = '%.4f', sokakrange = '%f' WHERE sokakID = '%d'",
	Sokak[i][sokakIsim],
	Sokak[i][sokakPos][0],
	Sokak[i][sokakPos][1],
	Sokak[i][sokakPos][2],
	Sokak[i][sokakRange],
	Sokak[i][sokakID]
	);
	mysql_query(sqlC, query);
	return 1;
}

stock GetStreetName(id)
{
	new isim[32];
	format(isim, sizeof(isim), Sokak[id][sokakIsim]);
	return isim;
}

stock GetNearestStreet(playerid)
{
	new id = -1;
	for(new i; i < MAX_STREETS; i++)
	{
		if(IsPlayerInRangeOfPoint(playerid, Sokak[i][sokakRange], Sokak[i][sokakPos][0], Sokak[i][sokakPos][1], Sokak[i][sokakPos][2]))
		{
			id = i;
			break;
		}
	}
	return id;
}
