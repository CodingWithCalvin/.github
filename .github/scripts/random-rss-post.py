#!/usr/bin/env python3
"""
Select a random blog post from an RSS feed, excluding recent posts.
Outputs JSON object of the selected post.
"""

import argparse
import sys
import json
import random
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from datetime import datetime, timedelta, timezone


def parse_rss(rss_file: str, exclude_days: int = 30) -> list[dict]:
    """Parse RSS file and return posts older than exclude_days."""
    try:
        tree = ET.parse(rss_file)
        root = tree.getroot()
    except ET.ParseError:
        return []

    channel = root.find('channel')
    if channel is None:
        return []

    cutoff_date = datetime.now(timezone.utc) - timedelta(days=exclude_days)
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

        # Skip recent posts
        if pub_date > cutoff_date:
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
            'pub_date': pub_date.strftime('%Y-%m-%d')
        }
        posts.append(post)

    return posts


def main():
    parser = argparse.ArgumentParser(description='Select a random blog post from an RSS feed')
    parser.add_argument('rss_file', help='Path to the RSS file')
    parser.add_argument('exclude_days', nargs='?', type=int, default=30,
                        help='Exclude posts newer than this many days (default: 30)')
    parser.add_argument('--exclude-urls', type=str, default='',
                        help='JSON array of URLs to exclude from selection')

    args = parser.parse_args()

    posts = parse_rss(args.rss_file, args.exclude_days)

    if not posts:
        print(json.dumps({}))
        sys.exit(0)

    # Filter out previously selected URLs if provided
    exclude_urls = set()
    if args.exclude_urls:
        try:
            exclude_urls = set(json.loads(args.exclude_urls))
        except json.JSONDecodeError:
            print(f"Warning: Could not parse exclude-urls JSON", file=sys.stderr)

    if exclude_urls:
        filtered_posts = [p for p in posts if p['url'] not in exclude_urls]
        # If all posts are excluded, reset and use full list
        if filtered_posts:
            posts = filtered_posts

    selected = random.choice(posts)
    print(json.dumps(selected))


if __name__ == '__main__':
    main()
