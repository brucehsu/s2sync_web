
$(document).ready(function() {
$('#content').keyup(function() {
    $('#word_count_indicator').html($('#content').val().length);
});


    $('#post_content').submit(function() {
        var formdata = $('#post_content').serialize();
        $.ajax({
            type: "POST",
            url: "/post",
            data: formdata,
            success: function(msg) {
                alert("msg");
            }
        });
    });
});