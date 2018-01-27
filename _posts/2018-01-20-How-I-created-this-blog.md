---
layout: post
title: How I created this blog
tags: jekyll github-pages
---

This post explains why I decided to use Jekyll for my blog and how you could set up your own blog using Jekyll and GitHub Pages.

## What I was looking for

When deciding on which platform to use for my software development blog, I first looked at a number of popular services like Wordpress and Medium. However, none of them was able to satisfy my main requirements:

- Make it straightforward to include source code directly in a post and get proper syntax highlighting (without having to use GitHub Gist or something similar)
- Give me full control over the look and feel of my blog

## Jekyll and GitHub Pages

If you're a software developer looking to start a blog, [Jekyll](https://jekyllrb.com/) is a great option. As the Jekyll documentation says:

> Jekyll is a simple, blog-aware, static site generator. It takes a template directory containing raw text files in various formats, runs it through a converter (like Markdown) and our Liquid renderer, and spits out a complete, ready-to-publish static website suitable for serving with your favorite web server.

Using Jekyll, you can simply write your blog posts as [Markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) files. Based on the layouts you define using HTML, (S)CSS and the Liquid template language, Jekyll then generates your blog as a static website. This means that basically any web server will be able to serve your blog. There's no need for PHP, a database or a separate backend server.

You can use any text editor to write your blog posts, although I would recommend an editor with Markdown support (like Visual Studio Code) that allows you to preview your posts as you write them. 

Including source code is easy. You just write blocks of code fenced by lines with three back-ticks. If you specify a language, you get syntax highlighting as well.

Source:

``````
```javascript
function () {
    alert('Hello world!');
}
```
``````

Result:

```javascript
function () {
    alert('Hello world!');
}
```

The fact that Jekyll generates your blog as a static website means that you can effortlessly host the generated files on a service like [GitHub Pages](https://pages.github.com/). However, GitHub Pages has another interesting feature: it has built-in Jekyll support. This means that you can put the source files for your Jekyll site inside your GitHub Pages repository and GitHub Pages will automatically generate your site for you and serve the generated pages.

## Jekyll Now

![Jekyll Now screenshot](/images/2018-01-20-How-I-created-this-blog/jekyll-now-theme-screenshot.jpg)

If you are looking for a quick way to set up a Jekyll blog on GitHub Pages, [Jekyll Now](https://github.com/barryclark/jekyll-now) is an excellent option. It contains all the necessary files to set up a basic Jekyll blog. Just fork the repository according to the instructions and you can immediately start putting your blog posts in the `_posts` directory. You don't even have to install anything on your own machine if you don't want to, as GitHub's online editor has built-in Markdown support.

If you want to modify the look and feel of your blog, you can start modifying `index.html`, `style.scss`, the layouts in the `_layouts` folder and the additional styles in the `_sass` folder.

The look of any highlighted code on your blog is defined in the `_sass/_variables.scss` file. Jekyll uses [Rouge](http://rouge.jneen.net/) for syntax highlighting. Rouge transforms source code into HTML where the code is divided into `<span>` elements with a class that indicates what they represent (keyword, string literal, ...). The `_sass/_variables.scss` file then defines what color to use for each of those classes. I based my version of this file on [the highlighing style used by the GitHub Pages Modernist theme](https://github.com/pages-themes/modernist/blob/master/_sass/rouge-base16-dark.scss).

## Structure of a post

Every blog post is a file that starts with [YAML front matter](https://jekyllrb.com/docs/frontmatter/). This is what the front matter for this post looks like:

```
---
layout: post
title: How I created this blog
tags: jekyll github-pages
---
```

The title and tags should be self-explanatory. The layout variable refers to an HTML file (also including some Liquid code) that defines what a post looks like.

After the YAML front matter, you can use a number of different formats. Markdown is supported out of the box and fits my use case very well, so that is what I decided to use.

If you want to have a look at what the Markdown file for this post looks like, you can find it [here](https://github.com/thehumanmicrophone/thehumanmicrophone.github.io-source/blob/master/_posts/2018-01-20-How-I-created-this-blog.md).

## Running Jekyll locally

If you're using Jekyll Now with GitHub Pages, you can in principle create a blog without having to install Jekyll (and Ruby, which is what Jekyll runs on) on your local machine. A big drawback of this approach is that, in order to see the result of any changes you make, you need to commit them to your GitHub Pages repository and wait for your site to be generated again. If you want to make some significant changes to the look and feel of your site, I would recommend to install Jekyll locally. This way, you can generate your site locally during development and only push to GitHub when you are satisfied with the result. See [this guide](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/) for more information on how to do that. An important part of this setup is the `github-pages` gem, which contains Jekyll and the Jekyll Plugins supported by GitHub Pages. If you let GitHub Pages generate your site for you, it is important to keep you local version of the `github-pages` gem up to date so the way your site is generated locally is consistent with the way it will be generated by GitHub Pages.

Another possible approach is to generate your site locally and only push the generated site (instead of the Jekyll source files) to your GitHub Pages repository. This way, you're not actually using GitHub Pages' Jekyll capabilities anymore (although you can still use the `github-pages` gem to get you started with Jekyll and a set of well-supported Jekyll Plugins). This approach has a number of advantages:

- GitHub Pages runs Jekyll with the `--safe` flag, which means that only Jekyll Plugins that are part of the official repository get executed. If you generate your site locally, you can use any plugin you want (like, for example, the [tagging plugin](https://github.com/pattex/jekyll-tagging) that I am using on this blog).
- If GitHub Pages makes any changes to the way their built-in Jekyll behaves, you can decide if and when you are going to adjust your site and local setup.

These advantages are the reason why I chose to generate my site locally and only upload the generated site to GitHub Pages. Of course, this approach has the disadvantage that it is now your own responsibility to make sure that your generated site is consistent with the source files. However, as I am the only person maintaining this blog, that shouldn't be a problem.

## Resources

- [Jekyll](https://jekyllrb.com/)
- [Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
- [GitHub Pages](https://pages.github.com/)
- [Rouge](http://rouge.jneen.net/)
- [Setting up your GitHub Pages site locally with Jekyll](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/)