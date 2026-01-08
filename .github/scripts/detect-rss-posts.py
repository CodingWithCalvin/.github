#!/usr/bin/env python3
"""
Detect blog posts from an RSS feed that match a target date.
Outputs JSON array of matching posts.
"""

import sys
import json
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime


def parse_rss(rss_file: str, target_date: str) -> list[dict]:
    """Parse RSS file and return posts matching target date."""
    try:
        tree = ET.parse(rss_file)
        root = tree.getroot()
    except ET.ParseError:
        return []

    channel = root.find('channel')
    if channel is None:
        return []

    # Define namespaces for custom elements
    namespaces = {'bluesky': 'https://bsky.app/ns'}

    posts = []
    for item in channel.findall('item'):
        pub_date_elem = item.find('pubDate')
        if pub_date_elem is None:
            continue

        pub_date_str = pub_date_elem.text
        try:
            pub_date = parsedate_to_datetime(pub_date_str)
        except (ValueError, TypeError):
            continue

        post_date = pub_date.strftime('%Y-%m-%d')

        if post_date != target_date:
            continue

        # Skip posts that already have a blueskyPostId (already announced)
        bluesky_post_id = item.find('bluesky:postId', namespaces)
        if bluesky_post_id is not None and bluesky_post_id.text:
            continue

        title = item.find('title')
        link = item.find('link')
        description = item.find('description')
        enclosure = item.find('enclosure')

        categories = []
        for cat in item.findall('category'):
            if cat.text:
                categories.append(cat.text)

        hashtags = ' '.join(['#' + cat.replace(' ', '') for cat in categories])

        post = {
            'title': title.text if title is not None else '',
            'url': link.text if link is not None else '',
            'description': description.text if description is not None else '',
            'categories': categories,
            'hashtags': hashtags,
            'image_url': enclosure.get('url') if enclosure is not None else '',
            'pub_date': post_date
        }
        posts.append(post)

    return posts


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <target_date> <rss_file>", file=sys.stderr)
        sys.exit(1)

    target_date = sys.argv[1]
    rss_file = sys.argv[2]

    posts = parse_rss(rss_file, target_date)
    print(json.dumps(posts))


if __name__ == '__main__':
    main()
