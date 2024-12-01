from ipaddress import ip_address
from urllib.parse import urlparse, parse_qs

import whois
import datetime

from tld import get_tld, Result


# check %, for spaces
# check @, for
special_chars = ["@", "?", "-", "=", "#", "%", "+", ".", "$", "!", "*", ",", "//"]


def add_url_len(data):
    data["url_len"] = data["url"].apply(lambda x: len(str(x)))


def add_domain(data):
    data["tld"] = data["url"].apply(lambda u: get_top_level_domain(u))
    data["tld_len"] = data["tld"].apply(lambda u: 0 if u is None else len(u))


def using_https(data):
    data["is_https"] = data["url"].apply(lambda u: u.count("https") > 1)


def count_http(data):
    data["count_http"] = data["url"].apply(lambda u: u.count("http"))


def count_www(data):
    data["count_www"] = data["url"].apply(lambda u: u.count("www"))


def count_embeds(data):
    data["count_embed"] = data["url"].apply(lambda u: no_of_embed(u))


def count_path(data):
    data["count_path"] = data["url"].apply(lambda u: no_of_dir(u))


def using_ip(data):
    data["using_ip"] = data["url"].apply(lambda u: having_ip_address(u))


def count_digits(data):
    data["count_digits"] = data["url"].apply(lambda u: digit_count(u))


def count_letters(data):
    data["count_letters"] = data["url"].apply(lambda u: letter_count(u))


def count_special_chars(data):
    for ch in special_chars:
        data[f"count{ch}"] = data["url"].apply(lambda u: u.count(ch))


def hostname_length(data):
    data["hostname_len"] = data["url"].apply(lambda u: len(urlparse(u).netloc))


def is_abnormal_url(data):
    data["is_abnormal"] = data["url"].apply(lambda u: is_abnormal(u))


def count_query_params(data):
    data["count_qp"] = data["url"].apply(lambda u: total_query_params(u))


## helpers


def total_query_params(u):
    try:
        return len(parse_qs(urlparse(u).query))
    except Exception:
        return 0


def get_top_level_domain(url):
    try:
        res: str | Result | None = get_tld(
            url, as_object=True, fail_silently=False, fix_protocol=True
        )
        if res is None or isinstance(res, str):
            return None
        pri_domain = res.parsed_url.netloc
    except Exception:
        pri_domain = None

    return pri_domain


def is_abnormal(url):
    try:
        domain = url.split("://")[-1].split("/")[0]

        whois_info = whois.whois(domain)

        creation_date = whois_info.creation_date
        if isinstance(creation_date, list):
            creation_date = creation_date[0]
        if creation_date and (datetime.datetime.now() - creation_date).days < 180:
            return 1

        if "REDACTED" in str(whois_info) or not whois_info.registrar:
            return 1

        # Add more conditions as needed, such as checking for suspicious registrars
        # For simplicity, we assume domains without a registrar are abnormal
        return 0  # Normal
    except Exception:
        # print(f"WHOIS lookup failed for {url}: {e}")
        return 1


def no_of_dir(url):
    urldir = urlparse(url).path
    return urldir.count("/")


def no_of_embed(url):
    urldir = urlparse(url).path
    return urldir.count("//")


def digit_count(url):
    return sum([1 for ch in url if ch.isnumeric()])


def letter_count(url):
    return sum([1 for ch in url if ch.isalpha()])


def having_ip_address(url):
    try:
        ip_address(url)
        return 1
    except Exception:
        return 0
