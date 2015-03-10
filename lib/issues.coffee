
fs = require 'fs'
request = require 'request'

token = '207e2ec811c24123b8e483b784534d3c690084e5'
outFilePfx = 'data-atom/comments-'

module.exports = 

  activate: -> 
      console.log 'start issues'
    # 
    # atom.workspace.open('issues.txt').then (editor) ->

      firstPage = 0
      lastPage  = 10
      
      page = firstPage - 1
      
      padChars = (num, len, chr = ' ') ->
        num = '' + num
        while num.length < len then num = chr + num
        num
      
      do oneIssuesPage = ->
        if ++page > lastPage
          console.log 'issues done'
          return
          
        filePath = outFilePfx + padChars(page, 4, '0') + '.txt'
        
        if fs.existsSync filePath then oneIssuesPage(); return
        
        url = "https://discuss.atom.io/c/features.json?page=" + page

        options = {url, method: 'GET', json: yes}

        request options, (err, res, body) =>
          {topics} = body.topic_list
          {created_at, id, posts_count, reply_count} = topics[0]
          
          if not topics.length then oneIssuesPage(); return
          
          pageHdr = '\n# page: ' + page + 
                    ', date: '   + created_at[0...10] +
                    '\n\n'
                        
          console.log pageHdr
          fs.appendFileSync filePath, pageHdr
          
          do oneIssue = ->
            if not (issue = topics.shift())
              process.nextTick oneIssuesPage
              return
            
            options.url = "https://discuss.atom.io/t/about-the-features-category/#{issue.id}.json"

            request options, (err, res, body) =>
              {posts} = body.post_stream
              
              for post in posts[1...]
                comment = post.cooked.replace /\<.*?\>/g, ''
                                     .replace /&.*?;/g, ' '
                                     .replace /\s+/g, ' '
                                     .replace /^\s+|\s+$/g, ''
                
                fs.appendFileSync filePath, '   ' + padChars(comment.length,   5     ) + 
                                              '-' + padChars(issue.id,         5, '0') + 
                                              '-' + padChars(post.id,          5, '0') + 
                                              '-' + padChars(post.post_number, 3, '0') +        
                                              ' ' + comment[0..100]                    + 
                                              '\n'
              process.nextTick oneIssue
                              
          