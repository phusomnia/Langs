module http::parser;

import http::request;
import core::log;

fn void parse_request(String raw)
{
	request::Request req;

	log::info(raw);
}