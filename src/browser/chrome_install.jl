import Base.Sys: islinux, isapple, iswindows
import HTTP, InfoZIP

function get_download_url()
    # https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html
    if islinux()
        "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F100002%2Fchrome-linux.zip?generation=1&alt=media"
    elseif isapple()
        "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Mac%2F100022%2Fchrome-mac.zip?generation=1&alt=media"
    elseif iswindows()
        "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2F100028%2Fchrome-win32.zip?generation=1&alt=media"
    else
        error("Unsupported platform")
    end
end

function download_chrome()
    url = get_download_url()
    file = HTTP.download(url)
    @info "Unzipping chrome"
    InfoZIP.unzip(file, joinpath(dirname(@__FILE__),"../"))
    @info "Removing zipfile"
    rm(file)
end
