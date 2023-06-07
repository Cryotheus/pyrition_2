local valid_extensions = {
	csv = true, dat = true,
	jpeg = true, jpg = true,
	json = true, mp3 = true,
	ogg = true, png = true,
	txt = true, vmt = true,
	vtf = true, wav = true,
	xml = true
}

local function download_loop(routine, url_list, prefix, path_prefix)
	local prefix = "^" .. string.PatternSafe(prefix)
	local url = table.remove(url_list)
	local url_path

	local function fail() coroutine.resume(routine) end

	local function success(body, _length, _headers, code)
		if code == 200 then
			local extension = string.GetExtensionFromFilename(url_path)
			local file_path = path_prefix .. url_path

			if not valid_extensions[extension] then file_path = file_path .. ".dat" end

			file.CreateDir(string.GetPathFromFilename(file_path))
			file.Write(file_path, body)
			coroutine.resume(routine)
		end
	end

	while url do
		url_path = string.gsub(url, prefix, "")

		http.Fetch(url, success, fail)
		coroutine.yield() --wait for a response from the HTTP request

		url = table.remove(url_list)
	end
end

function PYRITION:DownloadFiles(url_list, prefix, path_prefix)
	---Called by DownloadList to download the files in the list fetched.
	local routine
	routine = coroutine.create(function() download_loop(routine, url_list, prefix, path_prefix) end)

	coroutine.resume(routine)
end

function PYRITION:DownloadList(prefix, url_path, path_prefix)
	---Downloads all files listed in the page fetched.
	http.Fetch(prefix .. url_path, function(body, _length, _headers, code)
		if code == 200 then
			local url_list = string.Explode("\n", body)

			table.remove(url_list) --the last line is always empty
			self:DownloadFiles(url_list, prefix, path_prefix)
		end
	end)
end
